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

status_t queue_extract (queue_t * queue, void * data)
{
  queue_link_t * item = data;
  queue_link_t * kitem = queue -> head;

  watch (status_t)
  {
    ensure (queue != NULL && data != NULL, DNA_BAD_ARGUMENT);
    ensure (queue -> status != 0, DNA_ERROR);

    if (queue -> head == item)
    {
      queue -> head = item -> next;
    }
    else
    {
      while (kitem -> next != item && kitem -> next != NULL)
      {
        kitem = kitem -> next;
      }

      ensure (kitem -> next == item, DNA_ERROR);

      kitem -> next = item -> next;

      if (kitem -> next == NULL)
      {
        queue -> tail = kitem;
      }
    }

    item -> next = NULL;
    queue -> status -= 1;

    return DNA_OK;
  }
}

