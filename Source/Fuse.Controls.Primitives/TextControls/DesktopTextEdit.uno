using Uno;
using Uno.UX;
using Uno.Platform.EventSources;
using Fuse.Controls.FallbackTextRenderer;
using Fuse.Controls.Graphics;
using Fuse.Drawing;
using Fuse.Elements;
using Fuse.Input;
using Fuse.Internal;
using Fuse.Triggers;
using Fuse.Controls.Native;
using Fuse.Controls.FallbackTextEdit;

namespace Fuse.Controls
{
	extern (!Mobile) class DesktopTextEdit : TextEdit, INotifyFocus
	{
		public DesktopTextEdit(bool isMultiline): base(isMultiline)
		{
			_lineCache = new LineCache(OnTextEdited, InvalidateLineCacheLayout, isMultiline);
			_textWindow = new TextWindow(this, _lineCache);
			Children.Add(_textWindow);

			TextService.TextEntered.AddHandler(this, OnTextEntered);

			Pointer.Pressed.AddHandler(this, OnPointerPressed);
			Pointer.Moved.AddHandler(this, OnPointerMoved);
			Pointer.Released.AddHandler(this, OnPointerReleased);

			Keyboard.KeyPressed.AddHandler(this, OnKeyPressed);
		}

		bool UseGraphicsPlaceholder { get { return string.IsNullOrEmpty(Value); } }

		void INotifyFocus.OnFocusGained()
		{
			TextSource.BeginTextInput(0); //TODO: Remove this argument
			_selection = null;
			InvalidateLayout();
			InvalidateVisual();
		}

		void INotifyFocus.OnFocusLost()
		{
			TextSource.EndTextInput();
			_selection = null;

			if (_textWindow != null) _textWindow.InvalidateVisual();

			ResetWindowPosition();
			InvalidateLayout();
			InvalidateVisual();
		}

		protected override void OnPlaceholderTextChanged()
		{
			base.OnPlaceholderTextChanged();
			InvalidateVisual();
			InvalidateLayout();	
		}

		protected override void OnPlaceholderColorChanged()
		{
			base.OnPlaceholderColorChanged();
			InvalidateVisual();
			InvalidateLayout();	
		}

		internal override string RenderValue
		{
			get 
			{ 
				// Only use the built-in text rendering mechanism to render
				// the placeholder text
				return UseGraphicsPlaceholder ? PlaceholderText : null; 
			}
		}

		internal override float4 RenderColor
		{
			get { return UseGraphicsPlaceholder ? PlaceholderColor : Color; }
		}

		protected override void OnRooted()
		{
			base.OnRooted();

			if defined(!Mobile)
			{
				_caretBrush.Pin();
				UpdateManager.AddAction(Update);	
			}
		}

		protected override void OnUnrooted()
		{
			base.OnUnrooted();

			if defined(!Mobile)
			{
				_caretBrush.Unpin();
				UpdateManager.RemoveAction(Update);	
			}
		}

		protected override void OnIsPasswordChanged()
		{
			base.OnIsPasswordChanged();

			if (_lineCache == null)
				return;

			if (IsPassword)
			{
				_lineCache.Transform = new LineCachePasswordTransform();
			}
			else
			{
				_lineCache.Transform = null;
			}
		}

		protected override void OnValueChanged(IPropertyListener origin)
		{
			base.OnValueChanged(origin);
			UpdateValue(Value);
		}

		void UpdateValue(string value)
		{
			if (_lineCache == null)
				return;

			_lineCache.Text = value;

			_textWindow.InvalidateVisual();
			_caretPosition = Focus.IsWithin(this) ? _lineCache.GetLastTextPos() : new TextPosition(0, 0);
			_selection = null;
			
			InvalidateLayout();
			InvalidateVisual();
		}

		public string SelectedText { get { return _selection != null ? _lineCache.GetString(_selection) : ""; } }

		void Update()
		{
			if (Focus.IsWithin(this))
			{
				InvalidateVisual();
			}
			else
			{
				var pt = _lineCache.Transform as LineCachePasswordTransform;
				if (pt != null)
				{
					if (Time.FrameTime > _revealEnd)
					{
						if( pt.SetReveal( -1 ) )
							_lineCache.InvalidateVisual();	
					}
				}
			}
		}
		
		void InvalidateLineCacheLayout()
		{
			InvalidateLayout();
		}

		void OnTextEdited()
		{
			SetValueInternal(_lineCache.Text);
		}

		//for password temporary character veal
		double RevealTime = 2.0;
		double _revealEnd;

		bool IsWordWrapEnabled { get { return TextWrapping == Fuse.Controls.TextWrapping.Wrap; } }

		public void SelectAll()
		{
			_selection = _lineCache.GetFullTextSpan();
			_caretPosition = _lineCache.GetLastTextPos();
			InvalidateVisual();
		}

		WordWrapInfo _wrapInfo;

		protected override float2 GetContentSize(LayoutParams lp)
		{
			if defined (Mobile) return base.GetContentSize(lp);
			else
			{
				if (Font == null)
				return float2(0f);

				if (UseGraphicsPlaceholder)
					return Math.Ceil(base.GetContentSize(lp)) + 1;

				_wrapInfo = CreateWrapInfo(lp.X, lp.HasX);
				var r = Math.Ceil(GetTextBoundsSize(_wrapInfo)) + 1;

				if (lp.HasX)
					r.X = Math.Min(r.X, lp.X);
				return r;
			}
		}

		WordWrapInfo CreateWrapInfo(float wrapWidth, bool haveWidth)
		{
			var renderer = TextRenderer.GetTextRenderer(Font);

			return new WordWrapInfo(renderer, haveWidth && IsWordWrapEnabled, wrapWidth,
				FontSize, renderer.GetLineHeight(FontSize), 
				LineSpacing, AbsoluteZoom);
		}

		protected override float2 OnArrangeMarginBox(float2 position, LayoutParams lp)
		{
			if defined (Mobile) return base.OnArrangeMarginBox(position, lp);
			else
			{
				var sz = base.OnArrangeMarginBox(position, lp);
				_textWindow.ArrangeMarginBox(float2(0), LayoutParams.Create(sz));
				return sz;
			}
			
		}

		public override void Draw(DrawContext dc)
		{
			if defined(!Mobile) FallbackDraw(dc);
			else base.Draw(dc);
		}

		void FallbackDraw(DrawContext dc)
		{
			base.DrawVisual(dc);

			if (_wrapInfo == null)
				_wrapInfo = CreateWrapInfo(ActualSize.X,true);

			var textBoundsSize = GetClampedTextBoundsSize(_wrapInfo);
			var textBoundsWidth = textBoundsSize.X;

			BringCaretIntoView(_wrapInfo, textBoundsWidth);

			DrawBackground(dc, Opacity);
			
			if (!string.IsNullOrEmpty(Value))
				_textWindow.Draw(_wrapInfo, _selection, 
					Color, SelectionColor, 
					Value.Length, TextAlignment, textBoundsSize, -_windowPos, dc);

			if (Focus.IsWithin(this) && CaretColor.W > 0)
			{
				DrawCaret(_wrapInfo, textBoundsWidth, dc);	
				UpdateManager.PerformNextFrame(InvalidateVisual);
			}
		}

		SolidColor _caretBrush = new SolidColor();
		void DrawCaret(WordWrapInfo wrapInfo, float textBoundsWidth, DrawContext dc)
		{
			var caretRect = GetCaretRect(wrapInfo, textBoundsWidth);
			var pos = TextBoundsToControl(caretRect.Position);

			float blink = Math.Cos((float)(Time.FrameTime - _caretBlinkTime) * 2.0f * Math.PIf) * .5f + .5f;
			blink = 1.0f - Math.Pow(1.0f - blink, 4.3f);

			var caretSize = float2(1.0f, caretRect.Size.Y);
			_caretBrush.Color = float4(CaretColor.XYZ, CaretColor.W * blink);
			_caretBrush.Prepare(dc, caretSize);
			Fuse.Drawing.Primitives.Rectangle.Singleton.Fill(dc,this, caretSize, float4(0), _caretBrush, pos );
		}

		// Line cache
		LineCache _lineCache;

		Rect GetClampedTextBoundsRect(WordWrapInfo wrapInfo)
		{
			return new Rect(float2(0), GetClampedTextBoundsSize(wrapInfo));
		}

		float2 GetClampedTextBoundsSize(WordWrapInfo wrapInfo)
		{
			return Math.Max(GetTextBoundsSize(wrapInfo), ActualSize);
		}

		float2 GetTextBoundsSize(WordWrapInfo wrapInfo)
		{
			return _lineCache.GetBoundsSize(wrapInfo);
		}

		// Window
		TextWindow _textWindow;
		float2 _windowPos;

		void SetWindowPos(float2 p)
		{
			if (p != _windowPos)
				_textWindow.InvalidateVisual();
			_windowPos = p;
		}

		void ResetWindowPosition()
		{
			SetWindowPos(float2(0));
		}

		// Caret/Selection
		TextPosition _caretPosition = TextPosition.Default;
		TextPosition _interactionSelectionStartPos;
		TextSpan _selection;
		double _caretBlinkTime;

		void ResetCaretBlink()
		{
			_caretBlinkTime = Time.FrameTime;
		}

		void SetCaretPos(float2 p)
		{
			var wrapWidth = ActualSize.X;
			var wrapInfo = CreateWrapInfo(wrapWidth,true);
			var textBoundsWidth = GetClampedTextBoundsSize(wrapInfo).X;
			_caretPosition = _lineCache.BoundsToTextPos(wrapInfo, 
				TextAlignment, textBoundsWidth, ControlToTextBounds(p));
			BringCaretIntoView(wrapInfo, textBoundsWidth);
			ResetCaretBlink();
		}

		void BringCaretIntoView(WordWrapInfo wrapInfo, float textBoundsWidth)
		{
			var windowRect = new Rect(_windowPos, ActualSize);
			var caretRect = GetCaretRect(wrapInfo, textBoundsWidth);
			var textRect = GetClampedTextBoundsRect(wrapInfo);

			var caretVisibleRect = windowRect.MoveRectToContainRect(caretRect);
			var clampedRect = caretVisibleRect.MoveRectInsideRect(textRect);
			SetWindowPos(clampedRect.Position);
		}

		Rect GetCaretRect(WordWrapInfo wrapInfo, float textBoundsWidth)
		{
			var pos = _lineCache.TextPosToBounds(wrapInfo, 
				TextAlignment, textBoundsWidth, _caretPosition);
			var width = 2.0f;
			return new Rect(pos, float2(width, wrapInfo.LineHeight));
		}

		void DeleteSelection()
		{
			if (_selection == null)
				return;

			_caretPosition = _lineCache.DeleteSpan(_selection);

			_selection = null;
			_interactionSelectionStartPos = null;
		}

		// Transformations
		float2 ControlToWindow(float2 p)
		{
			return p;
		}

		float2 WindowToControl(float2 p)
		{
			return p;
		}

		float2 WindowToTextBounds(float2 p)
		{
			return p + _windowPos;
		}

		float2 TextBoundsToWindow(float2 p)
		{
			return p - _windowPos;
		}

		float2 ControlToTextBounds(float2 p)
		{
			return WindowToTextBounds(ControlToWindow(p));
		}

		float2 TextBoundsToControl(float2 p)
		{
			return WindowToControl(TextBoundsToWindow(p));
		}

		static SwipeGestureHelper _horizontalGesture = new SwipeGestureHelper(15.0f,
			new DegreeSpan(45.0f, 135.0f),	// Right
			new DegreeSpan(-45.0f, -135.0f));	// Left

		static SwipeGestureHelper _verticalGesture = new SwipeGestureHelper(15.0f,
			new DegreeSpan( -45.0f,   45.0f),
			new DegreeSpan(-135.0f, -180.0f),
			new DegreeSpan( 135.0f,  180.0f));

		void OnLostCapture()
		{
			Focus.ReleaseFrom(this);
			_selection = null;
			_down = -1;
		}

		float2 _startCoord = float2(0f);
		int _down = -1;

		void OnPointerPressed(object sender, PointerPressedArgs c)
		{
			if (_down == -1)
			{
				_startCoord = c.WindowPoint;
				_down = c.PointIndex;

				if (Focus.IsWithin(this))
				{
					c.TryHardCapture(this, OnLostCapture);
				}
				else
				{
					c.TrySoftCapture(this, OnLostCapture);
				}
				StartSelection(c.WindowPoint);
			}
		}

		void OnPointerMoved(object sender, PointerMovedArgs c)
		{
			if (_down != c.PointIndex)
				return;

			MoveSelection(c.WindowPoint);

			if (c.IsHardCapturedTo(this))
			{
				c.IsHandled = true;
			}
			else if (c.IsSoftCapturedTo(this))
			{
				var diff = c.WindowPoint - _startCoord;
				var withinBounds = _horizontalGesture.IsWithinBounds(diff);

				/*if (!withinBounds && _lineCache.Lines.Count > 1)
				{
					withinBounds = _verticalGesture.IsWithinBounds(diff);
				}*/

				if (withinBounds)
				{
					c.TryHardCapture(this, OnLostCapture);
					Focus.GiveTo(this);
				}
			}
		}

		void OnPointerReleased(object sender, PointerReleasedArgs c)
		{
			if (_down != c.PointIndex)
				return;

			if (c.IsHardCapturedTo(this))
			{
				c.ReleaseCapture(this);
				c.IsHandled = true;
			}
			if (c.IsSoftCapturedTo(this))
			{
				c.ReleaseCapture(this);
			}
			_down = -1;
		}


		void StartSelection(float2 windowPoint)
		{
			SetCaretPos(WindowToLocal(windowPoint));
			ResetCaretBlink();
			_selection = null;
			_interactionSelectionStartPos = _caretPosition;
			ClearPasswordReveal();
		}

		void MoveSelection(float2 windowPoint)
		{
			SetCaretPos(WindowToLocal(windowPoint));
			if (_interactionSelectionStartPos == null)
				_interactionSelectionStartPos = _caretPosition;
			_selection = _interactionSelectionStartPos != _caretPosition ? new TextSpan(_interactionSelectionStartPos, _caretPosition) : null;
		}

		string _placeholderFallback;

		void SetPlaceholderTextFallback()
		{

		}

		LineCachePasswordTransform PasswordTransform
		{
			get
			{
				if (_lineCache == null)
					return null;
				return _lineCache.Transform as LineCachePasswordTransform;
			}
		}

		void OnTextEntered(object sender, TextEnteredArgs args)
		{
			DeleteSelection();

			args.IsHandled = true;

			if (MaxLength != 0 && Value.Length >= MaxLength)
				return;

			foreach (var character in args.Text)
			{
				if (character == '\n' || character == '\r' || (int)character < 32)
					continue;

				_caretPosition = _lineCache.InsertChar(_caretPosition, character);
				if( PasswordTransform != null )
				{
					PasswordTransform.SetReveal( _caretPosition.Char - 1 );
					_revealEnd = Time.FrameTime + RevealTime;
				}

				var wrapWidth = ActualSize.X;
				var wrapInfo = CreateWrapInfo(wrapWidth,true);
				var textBoundsWidth = GetClampedTextBoundsSize(wrapInfo).X;
				BringCaretIntoView(wrapInfo, textBoundsWidth);
				ResetCaretBlink();
			}

		}

		void ClearPasswordReveal()
		{
			if( PasswordTransform != null )
				if( PasswordTransform.SetReveal( -1 ) )
					_lineCache.InvalidateVisual();
		}

		void OnKeyPressed(object sender, KeyPressedArgs args)
		{
			bool recognizedKey = false;

			var wrapWidth = ActualSize.X;
			var wrapInfo = CreateWrapInfo(wrapWidth,true);
			var textBoundsWidth = GetClampedTextBoundsSize(wrapInfo).X;

			ClearPasswordReveal();

			if (!IsReadOnly)
			{

				switch (args.Key)
				{
					case Uno.Platform.Key.Enter:
						if (IsMultiline)
						{
							DeleteSelection();
							_caretPosition = _lineCache.InsertNewline(_caretPosition);
						}
						else if(TextSource.IsTextInputActive)
							OnAction(TextInputActionType.Primary);

						recognizedKey = true;
						break;

					case Uno.Platform.Key.Delete:
						if (_selection == null)
						{
							_caretPosition = _lineCache.TryDelete(_caretPosition);
						}
						else
						{
							DeleteSelection();
						}

						recognizedKey = true;
						break;

					case Uno.Platform.Key.Backspace:
						if (_selection == null)
						{
							_caretPosition = _lineCache.TryBackspace(_caretPosition);
						}
						else
						{
							DeleteSelection();
						}

						recognizedKey = true;
						break;

					default: break;
				}
			}

			switch (args.Key)
			{
				case Uno.Platform.Key.A:
					if(!args.IsMetaKeyPressed)
						break;

					SelectAll();
					recognizedKey = true;
					break;

				case Uno.Platform.Key.Left:
					HandleLeftArrow(args);
					recognizedKey = true;
					break;

				case Uno.Platform.Key.Right:
					HandleRightArrow(args);
					recognizedKey = true;
					break;

				case Uno.Platform.Key.Up:
					var oldCaretPos = _caretPosition;
					_caretPosition = _lineCache.TryMoveUp(wrapInfo, 
						TextAlignment, textBoundsWidth, _caretPosition);

					if(args.IsShiftKeyPressed && _caretPosition.Line == oldCaretPos.Line)
					{
						_caretPosition = _lineCache.Home(wrapInfo, oldCaretPos);
					}

					Select(oldCaretPos, _caretPosition, args.IsShiftKeyPressed);
					recognizedKey = true;
					break;

				case Uno.Platform.Key.Down:
					var oldCaretPos = _caretPosition;
					_caretPosition = _lineCache.TryMoveDown(wrapInfo, 
						TextAlignment, textBoundsWidth, _caretPosition);

					if(args.IsShiftKeyPressed && _caretPosition.Line == oldCaretPos.Line)
					{
						_caretPosition = _lineCache.End(wrapInfo, oldCaretPos);
					}

					Select(oldCaretPos, _caretPosition, args.IsShiftKeyPressed);
					recognizedKey = true;
					break;

				case Uno.Platform.Key.Home:
					var oldCaretPos = _caretPosition;
					_caretPosition = _lineCache.Home(wrapInfo, _caretPosition);
					Select(oldCaretPos, _caretPosition, args.IsShiftKeyPressed);
					recognizedKey = true;
					break;

				case Uno.Platform.Key.End:
					var oldCaretPos = _caretPosition;
					_caretPosition = _lineCache.End(wrapInfo, _caretPosition);
					Select(oldCaretPos, _caretPosition, args.IsShiftKeyPressed);
					recognizedKey = true;
					break;

				default: break;
			}

			if (recognizedKey)
			{
				ResetCaretBlink();
				args.IsHandled = true;
			}
		}

		void HandleLeftArrow(KeyPressedArgs args)
		{
			if(args.IsMetaKeyPressed)
			{
				var oldCaretPosition = _caretPosition;
				_caretPosition = _lineCache.TryMoveOneWordLeft(_caretPosition);
				Select(oldCaretPosition, _caretPosition, args.IsShiftKeyPressed);
			}
			else
			{
				if(args.IsShiftKeyPressed)
				{
					var oldCaretPosition = _caretPosition;
					_caretPosition = _lineCache.TryMoveLeft(_caretPosition);

					SelectFunc(oldCaretPosition, _caretPosition);
				}
				else
				{
					if(_selection != null)
					{
						_caretPosition = _selection.Start;
						_selection = null;
					}
					else
					{
						_selection = null;
						_caretPosition = _lineCache.TryMoveLeft(_caretPosition);
					}
				}
			}
		}

		void HandleRightArrow(KeyPressedArgs args)
		{
			if(args.IsMetaKeyPressed)
			{
				var oldCaretPosition = _caretPosition;
				_caretPosition = _lineCache.TryMoveOneWordRight(_caretPosition);
				Select(oldCaretPosition, _caretPosition, args.IsShiftKeyPressed);
			}
			else
			{
				if(args.IsShiftKeyPressed)
				{
					var oldCaretPosition = _caretPosition;
					_caretPosition = _lineCache.TryMoveRight(_caretPosition);

					SelectFunc(oldCaretPosition, _caretPosition);
				}
				else
				{
					if(_selection != null)
					{
						_caretPosition = _selection.End;
						_selection = null;
					}
					else
					{
						_selection = null;
						_caretPosition = _lineCache.TryMoveRight(_caretPosition);
					}
				}
			}
		}

		void Select(TextPosition oldCaretPos, TextPosition newCaretPos, bool shouldSelect)
		{
			if(shouldSelect)
			{
				SelectFunc(oldCaretPos, newCaretPos);
			}
			else
			{
				_selection = null;
			}
		}

		void SelectFunc(TextPosition oldCaretPos, TextPosition newCaretPos)
		{
			bool movesLeft = oldCaretPos > newCaretPos;

			if(_selection == null)
			{
				if(movesLeft)
				{
					_selection = new TextSpan(newCaretPos, oldCaretPos);
				}
				else
				{
					_selection = new TextSpan(oldCaretPos, newCaretPos);
				}
			}
			else if(_selection.End > oldCaretPos)
			{
				if(movesLeft)
				{
					_selection = new TextSpan(newCaretPos, _selection.End);
				}
				else
				{
					_selection = new TextSpan(_selection.End, newCaretPos);
				}
			}
			else if(_selection.Start <= oldCaretPos)
			{
				if(movesLeft)
				{
					_selection = new TextSpan(newCaretPos, _selection.Start);
				}
				else
				{
					_selection = new TextSpan(_selection.Start, newCaretPos);
				}
			}
		}
	}
}
