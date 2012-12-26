# Copyright (C) 2012  Ruby-GNOME2 Project Team
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

module GObjectIntrospection
  class ObjectInfo
    alias_method :__methods__, :methods

    collections = [
      "interfaces",
      "fields",
      "properties",
      "methods",
      "signals",
      "vfuncs",
      "constants",
    ]
    collections.each do |collection|
      n_getter = "n_#{collection}"
      if collection.end_with?("ies")
        singular = collection.sub(/ies\z/, "y")
      else
        singular = collection.sub(/s\z/, "")
      end
      getter = "get_#{singular}"
      define_method(collection) do
        send(n_getter).times.collect do |i|
          send(getter, i)
        end
      end
    end
  end
end
