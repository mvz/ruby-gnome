#!/usr/bin/env ruby
#
# Copyright (C) 2013-2022  Ruby-GNOME Project Team
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

require_relative "../../glib2/test/run-test"

run_test(__dir__,
         [
           "glib2",
           "gobject-introspection",
           "atk",
           "cairo-gobject",
           "gdk_pixbuf2",
           "gio2",
           "pango",
           "gdk4",
         ]) do
  begin
    require "gdk4"
  rescue GObjectIntrospection::RepositoryError
    puts("Omit because typelib file doesn't exist: #{$!.message}")
    exit(true)
  end

  require_relative "gdk-test-utils"
end
