/****h* memory/allocator
 * SUMMARY
 * Base functions for the kernel allocator.
 ****
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

#ifndef DNA_MEMORY_KERNEL_PRIVATE_H
#define DNA_MEMORY_KERNEL_PRIVATE_H

#include <stdint.h>
#include <stdbool.h>
#include <Core/Core.h>
#include <DnaTools/Status.h>

/****d* kernel/DNA_MM_MAX_POW2_INDEX
 * SUMMARY
 * Defines the minimum pow2 index.
 *
 * SOURCE
 */

#define DNA_MM_MAX_POW2_INDEX 20

/*
 ****/

/****t* kernel/kernel_allocator_t
 * SUMMARY
 * Type of the kernel allocator.
 *
 * SOURCE
 */

typedef struct _kernel_allocator
{
  spinlock_t lock;
  uint32_t * base;
  uint32_t * free[DNA_MM_MAX_POW2_INDEX + 1];
}
kernel_allocator_t;

/*
 ****/

extern uint32_t * OS_KERNEL_HEAP_ADDRESS;
extern uint32_t OS_KERNEL_HEAP_SIZE;

extern kernel_allocator_t kernel_allocator;

extern void * kernel_malloc (uint32_t size, bool erase);
extern status_t kernel_free (void * area);

#endif
