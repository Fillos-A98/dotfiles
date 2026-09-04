#include "art.h"
#include <gio/gio.h>
#include <gdk-pixbuf/gdk-pixbuf.h>
#include <string.h>
#include <stdlib.h>

// Suppress deprecated warnings for gdk_texture_new_for_pixbuf (still fully functional)
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"

void clear_album_art_container(GtkWidget *container) {
    GtkWidget *child = gtk_widget_get_first_child(container);
    while (child) {
        GtkWidget *next = gtk_widget_get_next_sibling(child);
        gtk_widget_unparent(child);
        child = next;
    }
}

GtkWidget* load_album_art_to_container(const gchar *art_url, GtkWidget *container, gint size) {
    if (!art_url || strlen(art_url) == 0 || !container) return NULL;

    GdkPixbuf *pixbuf = NULL;

    if (g_str_has_prefix(art_url, "file://")) {
        gchar *file_path = g_filename_from_uri(art_url, NULL, NULL);
        if (file_path && g_file_test(file_path, G_FILE_TEST_EXISTS)) {
            GError *error = NULL;
            pixbuf = gdk_pixbuf_new_from_file_at_scale(file_path, size, size, FALSE, &error);
            if (error) {
                g_error_free(error);
                pixbuf = NULL;
            }
        }
        g_free(file_path);
    } else if (g_str_has_prefix(art_url, "http://") || g_str_has_prefix(art_url, "https://")) {
        gchar *tmp_path = g_strdup_printf("/tmp/hyprwave-cover-%u.jpg", g_random_int());

        gchar *argv[] = {
            "curl",
            "-L",
            "--fail",
            "--silent",
            "--show-error",
            "--max-time", "10",
            "-o", tmp_path,
            (gchar *)art_url,
            NULL
        };

        GError *error = NULL;
        gint status = 0;

        if (g_spawn_sync(NULL, argv, NULL, G_SPAWN_SEARCH_PATH,
                         NULL, NULL, NULL, NULL, &status, &error) &&
            status == 0) {
            pixbuf = gdk_pixbuf_new_from_file_at_scale(
                tmp_path, size, size, FALSE, &error
            );
        }

        if (error) {
            g_error_free(error);
        }

        remove(tmp_path);
        g_free(tmp_path);
    }

    if (!pixbuf) return NULL;

    // Create image widget - let GTK4 handle texture creation/cleanup
    GtkWidget *image = gtk_picture_new_for_pixbuf(pixbuf);
    gtk_widget_set_size_request(image, size, size);

    // For larger sizes (main widget), add extra layout controls
    if (size > 100) {
        gtk_picture_set_can_shrink(GTK_PICTURE(image), TRUE);
        gtk_picture_set_content_fit(GTK_PICTURE(image), GTK_CONTENT_FIT_CONTAIN);
        gtk_widget_set_halign(image, GTK_ALIGN_CENTER);
        gtk_widget_set_valign(image, GTK_ALIGN_CENTER);
        gtk_widget_set_hexpand(image, FALSE);
        gtk_widget_set_vexpand(image, FALSE);
    } else {
        // For notifications, use simpler fill approach
        gtk_picture_set_content_fit(GTK_PICTURE(image), GTK_CONTENT_FIT_COVER);
    }

    // Clear existing art and add new
    clear_album_art_container(container);
    gtk_box_append(GTK_BOX(container), image);

    g_object_unref(pixbuf);  // GTK4 owns the texture now

    return image;
}

#pragma GCC diagnostic pop
