require 'gtksourceview3'

# This is an example of creating a derived class with vfunc implementations.

Gtk.init

class TestProvider < GLib::Object
  include GtkSource::CompletionProvider

  type_register

  def get_name
    'Test Provider'
  end

  def get_priority
    1
  end

  def match(_context)
    true
  end

  def populate(context)
    icon = Gtk::IconTheme.get_default.load_icon(Gtk::STOCK_DIALOG_INFO, 16, 0)

    proposals = [
      GtkSource::CompletionItem.new("Proposal 1", "Proposal 1", icon, "blah 1"),
      GtkSource::CompletionItem.new("Proposal 2", "Proposal 2", icon, "blah 2"),
      GtkSource::CompletionItem.new("Proposal 3", "Proposal 3", icon, "blah 3"),
    ]
    context.add_proposals(self, proposals, true)
  end
end

win = Gtk::Window.new :toplevel
win.show
win.signal_connect("destroy") { Gtk.main_quit }

vbox = Gtk::Box.new(:vertical, 0)
win.add vbox

lm = GtkSource::LanguageManager.default
lang = lm.get_language "ruby"
buffer = GtkSource::Buffer.new lang
@source = GtkSource::View.new buffer

test_provider = TestProvider.new
completion = @source.completion
completion.add_provider test_provider

vbox.pack_start @source, expand: true, fill: true, padding: 0

win.show_all
Gtk.main
