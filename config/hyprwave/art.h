#ifndef ART_H
#define ART_H

#include <gtk/gtk.h>

// Load album art from URL (file:// or http(s)://) and append to container
// Returns the created GtkPicture widget, or NULL on failure
// The caller owns the container but the widget is automatically added
GtkWidget* load_album_art_to_container(const gchar *art_url, GtkWidget *container, gint size);

// Clear all children from an album art container
void clear_album_art_container(GtkWidget *container);

#endif // ART_H
