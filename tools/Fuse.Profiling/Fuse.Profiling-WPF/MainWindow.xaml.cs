using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Threading;
using System.Windows;
using System.Windows.Threading;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.Windows.Shapes;
using Fuse.Profiling;

namespace Fuse.Profiling_WPF
{
	/// <summary>
	/// Interaction logic for MainWindow.xaml
	/// </summary>
	public partial class MainWindow : Window
	{



		public MainWindow()
		{
			InitializeComponent();

			var host = new Host();
			var profiler = new Profiler(x => _listBox.Dispatcher.Invoke(x));

			DataContext = profiler;

			Task.Run(() =>
				{
					while (true)
					{
						host.AcceptProfileClient(profiler);
					}
				});
		}

        private void Border_MouseDown(object sender, MouseButtonEventArgs e)
        {
            var frame = (Fuse.Profiling.Frame)(sender as FrameworkElement).Tag;

			_treeView.DataContext = frame.Root;
        }

		private void MenuItem_Click(object sender, RoutedEventArgs e)
		{
			_treeView.DataContext = null;
			((Profiler)DataContext).Frames.Clear();
		}
	}
}
