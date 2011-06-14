/*
 * Copyright (C) 2007 TIMA Laboratory
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
 */

#include <DnaTools/DnaTools.h>

void * queue_rem (queue_t * queue)
{
  queue_link_t * item = NULL;

  watch (void *)
  {
    ensure (queue -> status != 0, NULL);

    item = queue -> head;
    queue -> status -= 1;

    queue -> head = item -> next;
    check (queue_error, queue -> head != NULL ||
        (queue -> head == NULL && queue -> status == 0), NULL);

    item -> next = NULL;

    return item;
  }

  rescue (queue_error)
  {
    log (PANIC_LEVEL, "Q(0x%x): status %d, item 0x%x",
        queue, queue -> status, item);

    leave;
  }
}

