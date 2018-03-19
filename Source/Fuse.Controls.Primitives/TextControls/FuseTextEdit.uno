using Fuse.Controls.FuseTextRenderer;
using Fuse.Drawing;
using Fuse.Gestures;
using Fuse.Input;
using Fuse.Text.Edit;
using Fuse.Text;
using Uno.Collections;
using Uno.Platform.EventSources;
using Uno.UX;
using Uno;

namespace Fuse.Controls
{
	extern (!Mobile) class FuseTextEdit : TextEdit, INotifyFocus
	{
		static SwipeGestureHelper _horizontalGesture = new SwipeGestureHelper(15.0f,
			new DegreeSpan(45.0f, 135.0f), // Right
			new DegreeSpan(-45.0f, -135.0f)); // Left

		double _caretBlinkTime;
		float _caretBlinkIntensity;
		SolidColor _caretBrush = new SolidColor();
		SolidColor _selectionBrush = new SolidColor();
		bool _isSelecting = false;
		CaretIndex _selectionStart;
		CaretIndex _caretIndex;
		int _pressedPointIndex = -1;
		float2 _pressedCoord;

		TextRenderer TextRenderer { get { return _textRenderer as TextRenderer; } }

		public FuseTextEdit(bool isMultiLine)
			: base(isMultiLine)
		{
			TextService.TextEntered.AddHandler(this, OnTextEntered);

			Pointer.Pressed.AddHandler(this, OnPointerPressed);
			Pointer.Moved.AddHandler(this, OnPointerMoved);
			Pointer.Released.AddHandler(this, OnPointerReleased);

			Keyboard.KeyPressed.AddHandler(this, OnKeyPressed);
		}

		bool UsePlaceholder
		{
			get { return string.IsNullOrEmpty(Value); }
		}

		static string MakePassword(string str)
		{
			if (string.IsNullOrEmpty(str)) return str;

			return string.Empty.PadRight(str.Length, '\u2022');
		}

		internal override string RenderValue
		{
			get
			{
				return UsePlaceholder
					? PlaceholderText
					: (IsPassword
						? MakePassword(Value)
						: Value);
			}
		}

		internal override float4 RenderColor
		{
			get { return UsePlaceholder ? PlaceholderColor : Color; }
		}

		static List<List<PositionedRun>> _placeholderPositionedRuns
			= new List<List<PositionedRun>>();

		CaretContext CreateCaretContext()
		{
			// When rendering the placeholder the text-renderer's positioned runs
			// shouldn't be used for the caret since they don't correspond to the text
			// that the user is entering.
			var positionedRuns = UsePlaceholder
				? _placeholderPositionedRuns
				: TextRenderer.GetPositionedRuns();
			return new CaretContext(positionedRuns, Value);
		}

		protected override void OnValueChanged(IPropertyListener origin)
		{
			_isSelecting = false;
			base.OnValueChanged(origin);
		}

		void INotifyFocus.OnFocusGained()
		{
			_isSelecting = false;
			_caretBlinkTime = Time.FrameTime;
			TextSource.BeginTextInput(0);
			InvalidateVisual();
			UpdateManager.AddAction(AnimateCaret);
		}

		void INotifyFocus.OnFocusLost()
		{
			UpdateManager.RemoveAction(AnimateCaret);
			_isSelecting = false;
			TextSource.EndTextInput();
			InvalidateVisual();
		}

		void OnTextEntered(object sender, TextEnteredArgs args)
		{
			args.IsHandled = true;
			DeleteSelection();

			if (MaxLength != 0 && Value.Length >= MaxLength)
				return;

			foreach (var c in args.Text)
			{
				if (c == '\n' || c == '\r' || Char.IsControl(c))
					continue;

				var caretContext = CreateCaretContext();
				Value = caretContext.Insert(c, ref _caretIndex);
			}
		}

		void OnPointerPressed(object sender, PointerPressedArgs c)
		{
			if (_pressedPointIndex == -1)
			{
				_pressedPointIndex = c.PointIndex;
				_pressedCoord = c.WindowPoint;

				if (Focus.IsWithin(this))
					c.TryHardCapture(this, OnLostCapture);
				else
					c.TrySoftCapture(this, OnLostCapture);

				var pos = WindowToLocal(c.WindowPoint) * Viewport.PixelsPerPoint;
				var caretContext = CreateCaretContext();
				_selectionStart = caretContext.GetClosest(pos, TextRenderer.Font.Value.LineHeight);
				_caretIndex = _selectionStart;
			}
		}

		void OnLostCapture()
		{
			_isSelecting = false;
			_pressedPointIndex = -1;
		}

		void OnPointerMoved(object sender, PointerMovedArgs c)
		{
			if (_pressedPointIndex != c.PointIndex)
				return;

			var pos = WindowToLocal(c.WindowPoint) * Viewport.PixelsPerPoint;
			var caretContext = CreateCaretContext();
			_caretIndex = caretContext.GetClosest(pos, TextRenderer.Font.Value.LineHeight);
			_isSelecting = true;

			if (c.IsHardCapturedTo(this))
			{
				c.IsHandled = true;
			}
			else if (c.IsSoftCapturedTo(this))
			{
				if (_horizontalGesture.IsWithinBounds(c.WindowPoint - _pressedCoord))
				{
					c.TryHardCapture(this, OnLostCapture);
					Focus.GiveTo(this);
				}
			}
		}

		void OnPointerReleased(object sender, PointerReleasedArgs c)
		{
			if (_pressedPointIndex != c.PointIndex)
				return;

			if (_selectionStart == _caretIndex)
				_isSelecting = false;

			if (c.IsHardCapturedTo(this))
			{
				c.ReleaseCapture(this);
				c.IsHandled = true;
			}
			else if (c.IsSoftCapturedTo(this))
			{
				c.ReleaseCapture(this);
			}
			_pressedPointIndex = -1;
		}

		void OnKeyPressed(object sender, KeyPressedArgs args)
		{
			var caretContext = CreateCaretContext();
			switch (args.Key)
			{
				case Uno.Platform.Key.A:
					if (args.IsMetaKeyPressed)
					{
						_selectionStart = caretContext.LeftMost();
						_caretIndex = caretContext.RightMost();
						_isSelecting = true;
					}
					break;
				case Uno.Platform.Key.Left:
					MovementKeyPressed(args.IsShiftKeyPressed);
					_caretIndex = caretContext.MoveLeft(_caretIndex);
					break;
				case Uno.Platform.Key.Right:
					MovementKeyPressed(args.IsShiftKeyPressed);
					_caretIndex = caretContext.MoveRight(_caretIndex);
					break;
				case Uno.Platform.Key.Up:
					MovementKeyPressed(args.IsShiftKeyPressed);
					_caretIndex = caretContext.MoveUp(_caretIndex);
					break;
				case Uno.Platform.Key.Down:
					MovementKeyPressed(args.IsShiftKeyPressed);
					_caretIndex = caretContext.MoveDown(_caretIndex);
					break;
				case Uno.Platform.Key.Home:
					MovementKeyPressed(args.IsShiftKeyPressed);
					_caretIndex = caretContext.LeftMost();
					break;
				case Uno.Platform.Key.End:
					MovementKeyPressed(args.IsShiftKeyPressed);
					_caretIndex = caretContext.RightMost();
					break;
				default: break;
			}

			if (!IsReadOnly)
			{
				switch (args.Key)
				{
					case Uno.Platform.Key.Enter:
						if (IsMultiline)
						{
							DeleteSelection();
							if (MaxLength != 0 && Value.Length >= MaxLength)
								break;
							Value = caretContext.Insert('\n', ref _caretIndex);
							_caretBlinkTime = Time.FrameTime;
						}
						else if (TextSource.IsTextInputActive)
						{
							OnAction(TextInputActionType.Primary);
						}
						break;
					case Uno.Platform.Key.Delete:
						if (_isSelecting)
							DeleteSelection();
						else
							Value = caretContext.Delete(ref _caretIndex);
						_caretBlinkTime = Time.FrameTime;
						break;
					case Uno.Platform.Key.Backspace:
						if (_isSelecting)
							DeleteSelection();
						else
							Value = caretContext.Backspace(ref _caretIndex);
						_caretBlinkTime = Time.FrameTime;
						break;
					default: break;
				}
			}
		}

		void DeleteSelection()
		{
			if (_isSelecting)
			{
				var caretContext = CreateCaretContext();
				Value = caretContext.DeleteSpan(_selectionStart, ref _caretIndex);
				_isSelecting = false;
			}
		}

		void MovementKeyPressed(bool isShiftKeyPressed)
		{
			_caretBlinkTime = Time.FrameTime;
			if (isShiftKeyPressed)
			{
				if (!_isSelecting)
				{
					_isSelecting = true;
					_selectionStart = _caretIndex;
				}
			}
			else
			{
				_isSelecting = false;
			}
		}

		protected override void OnRooted()
		{
			base.OnRooted();

			_caretBrush.Pin();
			_selectionBrush.Pin();
		}

		protected override void OnUnrooted()
		{
			base.OnUnrooted();

			_selectionBrush.Unpin();
			_caretBrush.Unpin();
		}

		protected override void DrawVisual(DrawContext dc)
		{
			if (Focus.IsWithin(this) && _isSelecting)
				DrawTextSelection(dc);

			base.DrawVisual(dc);

			if (Focus.IsWithin(this) && CaretColor.W > 0)
				DrawCaret(dc);
		}

		void AnimateCaret()
		{
			_caretBlinkIntensity = Math.Cos((float)(Time.FrameTime - _caretBlinkTime) * 2.0f * Math.PIf) * .5f + .5f;
			_caretBlinkIntensity = 1.0f - Math.Pow(1.0f - _caretBlinkIntensity, 4.3f);
			InvalidateVisual();
		}

		void DrawCaret(DrawContext dc)
		{
			var caretContext = CreateCaretContext();
			var caretPosition = Math.Floor(caretContext.GetVisualPosition(_caretIndex) + 0.5f) / Viewport.PixelsPerPoint;
			var caretSize = float2(1, TextRenderer.Font.Value.LineHeight) / Viewport.PixelsPerPoint;
			var caretRect = new Rect(caretPosition, caretSize);

			var pos = caretRect.Position;

			_caretBrush.Color = float4(CaretColor.XYZ, CaretColor.W * _caretBlinkIntensity);
			_caretBrush.Prepare(dc, caretSize);
			Fuse.Drawing.Primitives.Rectangle.Singleton.Fill(dc, this, caretSize, float4(0), _caretBrush, pos);
		}

		void DrawTextSelection(DrawContext dc)
		{
			var caretContext = CreateCaretContext();

			_selectionBrush.Color = SelectionColor;
			_selectionBrush.Prepare(dc, TextRenderer.GetRenderBounds().Size);

			var selectionRects = caretContext.GetVisualRects(
				_selectionStart,
				_caretIndex,
				TextRenderer.Font.Value.LineHeight);

			foreach (var rect in selectionRects)
			{
				var pos = Math.Floor(rect.Position / Viewport.PixelsPerPoint + 0.5f);
				var size = Math.Floor(rect.Size / Viewport.PixelsPerPoint + 0.5f);
				Fuse.Drawing.Primitives.Rectangle.Singleton.Fill(dc, this, size, float4(0), _selectionBrush, pos);
			}
		}
	}
}
