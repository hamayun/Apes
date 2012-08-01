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

#include <Private/Core.h>

/****f* ThreadPrivate/thread_bootstrap
 * SUMMARY
 * The code required to boostrap a thead.
 *
 * SYNOPSIS
 */

int32_t thread_bootstrap (void * p_signature)

/*
 * ARGUMENTS
 * A thread signature.
 * 
 * RESULT
 * Ignored.
 *
 * SOURCE
 */

{
  thread_signature_t * signature = (thread_signature_t *) p_signature;

  thread_exit (signature -> handler (signature -> arguments));
  return 0;
}

/*
 ****/

