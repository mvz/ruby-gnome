#!/usr/bin/env ruby
#
# Copyright (C) 2006-2015  Ruby-GNOME2 Project Team
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

require "gtk3"
require "optparse"
require "fileutils"

current_path = File.expand_path(File.dirname(__FILE__))

require "#{current_path}/demos.rb"

gresource_bin = "#{current_path}/demo.gresource"
gresource_xml = "#{current_path}/demo.gresource.xml"

system("glib-compile-resources",
       "--target", gresource_bin,
       "--sourcedir", current_path,
       gresource_xml)

gschema_bin = "#{current_path}/gschemas.compiled"

system("glib-compile-schemas", current_path)

at_exit do
  FileUtils.rm_f([gresource_bin, gschema_bin])
end

resource = Gio::Resource.load(gresource_bin)
Gio::Resources.register(resource)

ENV["GSETTINGS_SCHEMA_DIR"] = current_path

TITLE_COLUMN, FILENAME_COLUMN, STYLE_COLUMN = 0, 1, 2

def script_info(path)
  title = klass = depend = nil
  file = File.open(path)
  file.each do |ln|
    if !title && ln =~ /^=\s+(.*)$/
      title = Regexp.last_match(1)
      if title =~ /^(.*)\((.+?)\)$/
        title = Regexp.last_match(1)
        depend = Regexp.last_match(2)
      end
    elsif !klass && ln =~ /\s*class\s+([A-Z][A-Za-z0-9_]*)/
      klass = Regexp.last_match(1)
    end

    break if title && klass
  end

  fail "File not found: #{path}." unless klass

  return title, klass.intern, depend
end


def generate_index
  # Target scripts
  scripts = Dir.glob(File.join(File.dirname(__FILE__), '*.rb'))
  # Generate index tree
  children = {}
  index = []

  scripts.each do |script|
    # TODO remove the demos.rb when demos list is handled.
    next if ["common.rb", "main.rb", "demos.rb"].include?(File.basename(script))
    title, klass, depend = script_info(script)

    if depend and not Gtk.const_defined?(depend)
      next
    end

    if title =~ %r{^(.+?)/(.+)$}
      parent = $1
      child = $2

      unless children[parent]
        children[parent] = []
        index += [[parent, nil, nil, []]]
      end

      children[parent] += [[child, script, klass]]
    else
      index += [[title, script, klass]]
    end
  end

  # Sort children
  children.each_key do |parent|
    children[parent].sort! do |a, b|
      a[0] <=> b[0]
    end
  end

  # Expand children
  index.collect! do |row|
    if row[3]
      row[3] = children[row[0]]
    end

    row
  end

  index.sort! do |a, b|
    a[0] <=> b[0]
  end

  index
end

def append_children(model, source, parent = nil)
  source.each do |title, filename, klass, children|
    iter = model.append(parent)
    puts "Sentinel: #{__LINE__}"
    iter[TITLE_COLUMN] = title
    iter[FILENAME_COLUMN] = filename
    iter[STYLE_COLUMN] = Pango::FontDescription::STYLE_NORMAL

    if children
      puts "Children Sentinel: #{__LINE__}"
      append_children(model, children, iter)
    end
    puts "append_children end Sentinel: #{__LINE__}"
  end
end

class Demo < Gtk::Application
  def initialize
    super("org.gtk.Demo", [:non_unique, :handles_command_line])

    @options = {}
    @exit_status = 0

    signal_connect "startup" do |application|
      puts "startup"
      @builder = Gtk::Builder.new(:resource => "/ui/main.ui")
      appmenu = @builder["appmenu"]
      application.set_app_menu(appmenu)
    end

    signal_connect "activate" do |application|
      puts "activate"
      begin
        run_application
      rescue => error
        report_error(error)
        @exit_status = 1
      end
    end

    signal_connect "command-line" do |application, command_line|
      puts "cmd"
      begin
        parse_command_line(command_line.arguments)
      rescue SystemExit => error
        error.status
      rescue OptionParser::InvalidOption => error
        puts error.message
        1
      rescue => error
        report_error(error)
        1
      else
        activate
        @exit_status
      end
    end
 end

  private
  def parse_command_line(arguments)
    parser = OptionParser.new
    parser.on("-r", "--run EXAMPLE", "Run an example") do |example|
      @options[:name] = example
    end
    parser.on("-a", "--autoquit", "Quit after a delay") do
      @options[:autoquit] = true
    end
    parser.on("-l", "--list", "List examples") do
      @options[:list] = true
    end
    parser.parse(arguments)
  end

  def report_error(error)
    puts "#{error.class}: #{error.message}"
    puts error.backtrace
  end

  def run_application
    if @options[:list]
      puts "list"
      # list_demos
      quit
    end

    if @options[:name]
      puts "name"
      # lookup_for_corresponding_demo
      # load_demo
    end

    if @options[:autoquit]
      puts "autoquit"
      GLib::Timeout.add(1) do
        #implement auto_quit
      end
    end

    window = @builder["window"]
    add_window(window)

    action = Gio::SimpleAction.new("run")
    action.signal_connect "activate" do |_action, _parameter|
      # activate_run
    end
    add_action(action)

    notebook = @builder["notebook"]
    info_textwiew = @builder["info-textview"]
    source_textview = @builder["source-textview"]
    headerbar = @builder["headerbar"]
    treeview = @builder["treeview"]
    model = treeview.model
    append_children(model, generate_index)
    
    sw = @builder["source-scrolledwindow"]
    scrollbar = sw.vscrollbar

    menu = Gtk::Menu.new

    item = Gtk::MenuItem.new("Start")
    menu.append(item)
    item.signal_connect "activate" do
      adj = scrollbar.adjustement
      adj.value = adj.get_lower
    end

    item = Gtk::MenuItem.new("End")
    menu.append(item)
    item.signal_connect "activate" do
      adj = scrollbar.adjustement
      adj.value = adj.get_upper - adj.get_page_size
    end

    menu.show_all

    scrollbar.signal_connect "popup-menu" do
      menu.popup(nil, nil, Gtk.current_event_time)
    end

    window.show_all
    puts "Run end Sentinel: #{__LINE__}"
  end
end

demo = Demo.new

exit(demo.run([$PROGRAM_NAME] + ARGV))
