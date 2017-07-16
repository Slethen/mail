// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2017 elementary LLC. (https://elementary.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authored by: Corentin Noël <corentin@elementary.io>
 */

public class Mail.MessageListItem : Gtk.ListBoxRow {
    public Camel.MessageInfo message_info { get; construct; }

    private Mail.WebView web_view;

    public MessageListItem (Camel.MessageInfo message_info) {
        Object (message_info: message_info);
        open_message.begin ();
    }

    construct {
        get_style_context ().add_class ("card");
        margin = 12;

        var from_label = new Gtk.Label (_("From:"));
        from_label.halign = Gtk.Align.END;
        from_label.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

        var to_label = new Gtk.Label (_("To:"));
        to_label.halign = Gtk.Align.END;
        to_label.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

        var subject_label = new Gtk.Label (_("Subject:"));
        subject_label.halign = Gtk.Align.END;
        subject_label.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

        var from_val_label = new Gtk.Label (message_info.from);
        from_val_label.halign = Gtk.Align.START;

        var to_val_label = new Gtk.Label (message_info.to);
        to_val_label.halign = Gtk.Align.START;
        to_val_label.ellipsize = Pango.EllipsizeMode.END;

        var subject_val_label = new Gtk.Label (message_info.subject);
        subject_val_label.halign = Gtk.Align.START;

        var avatar = new Granite.Widgets.Avatar.with_default_icon (64);

        var header = new Gtk.Grid ();
        header.margin = 6;
        header.column_spacing = 12;
        header.row_spacing = 6;
        header.attach (avatar, 0, 0, 1, 3);
        header.attach (from_label, 1, 0, 1, 1);
        header.attach (to_label, 1, 1, 1, 1);
        header.attach (subject_label, 1, 2, 1, 1);
        header.attach (from_val_label, 2, 0, 1, 1);
        header.attach (to_val_label, 2, 1, 1, 1);
        header.attach (subject_val_label, 2, 2, 1, 1);

        var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        separator.hexpand = true;

        web_view = new Mail.WebView ();
        web_view.margin = 6;

        var base_grid = new Gtk.Grid ();
        base_grid.expand = true;
        base_grid.orientation = Gtk.Orientation.VERTICAL;
        base_grid.add (header);
        base_grid.add (separator);
        base_grid.add (web_view);
        add (base_grid);
        show_all ();
    }

    private async void open_message () {
        Camel.MimeMessage message;
        var folder = message_info.summary.folder;
        try {
            message = yield folder.get_message (message_info.uid, GLib.Priority.DEFAULT, null);
            var content = get_mime_content (message);
            web_view.load_plain_text (content);
        } catch (Error e) {
            debug("Could not get message. %s", e.message);
        }
    }

    private static string get_mime_content (Camel.MimeMessage message) {
        string current_content = "";
        int content_priority = 0;
        var content = message.content as Camel.Multipart;
        if (content != null) {
            for (uint i = 0; i < content.get_number (); i++) {
                var part = content.get_part (i);
                int current_content_priority = get_content_type_priority (part.get_mime_type ());
                if (current_content_priority > content_priority) {
                    var byte_array = new GLib.ByteArray ();
                    var stream = new Camel.StreamMem.with_byte_array (byte_array);
                    part.decode_to_stream_sync (stream);
                    current_content = (string)byte_array.data;
                }
            }
        }

        return current_content;
    }

    public static int get_content_type_priority (string mime_type) {
        switch (mime_type) {
            case "text/plain":
                return 1;
            case "text/html":
                return 2;
            default:
                return 0;
        }
    }
}
