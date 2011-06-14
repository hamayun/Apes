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

#include <stdint.h>
#include <Private/MemoryManager.h>
#include <Core/Core.h>
#include <DnaTools/DnaTools.h>
#include <Processor/Processor.h>

/****f* kernel/kernel_free
 * SUMMARY
 * Free previously created kernel memory.
 *
 * SYNOPSIS
 */

status_t kernel_free (void * area)

/*
 * ARGUMENTS
 * * area : a pointer to the area to destroy
 *
 * FUNCTION
 * Destroy the area and register it as available.
 *
 * RESULT
 * * DNA_ERROR if the argument area is NULL.
 * * DNA_OK if the operation succeeded.
 *
 * SOURCE
 */

{
  bool stop_merge;
  uint32_t size_4octets, size_log, buddy_delta, address_delta;
  uint32_t slot_delta = 0, prev_slot_delta = 0;
  uint32_t * address_base = area - 4, * buddy_addr, * slot;
  uint32_t * prev_slot = NULL, * temp;
  status_t status = DNA_OK;
  interrupt_status_t it_status = 0;

  watch (status_t)
  {
    ensure (area != NULL, DNA_ERROR);

    /*
     * Enter a critical section to avoid concurrency issues.
     */

    it_status = cpu_trap_mask_and_backup();
    lock_acquire (& kernel_allocator . lock);

    /*
     * Compute variables related to the requested size.
     */

    size_4octets = address_base[0] >> 2;
    size_4octets += (size_4octets << 2) != address_base[0] ? 1 : 0;

    size_log = dna_log2 (size_4octets);
    size_log += size_4octets != (1 << size_log) ? 1 : 0;

    do
    {
      stop_merge = true;
      address_delta = (uint32_t)(address_base - kernel_allocator . base);
      buddy_delta = address_delta ^ (1 << size_log);
      buddy_addr = buddy_delta + kernel_allocator . base;

      slot = kernel_allocator . free[size_log];
      slot_delta = (uint32_t)(slot - kernel_allocator . base);

      while (slot != NULL && slot != buddy_addr)
      {
        prev_slot = slot;
        slot = (uint32_t *) kernel_allocator . base[slot_delta];
        slot_delta = (uint32_t)(slot - kernel_allocator . base);
      }

      if (slot == buddy_addr)
      {
        /*
         * On supprime la case libérée de la liste.
         */

        if (slot == kernel_allocator . free[size_log])
        {
          kernel_allocator . free[size_log] =
            (uint32_t *) kernel_allocator . base[slot_delta];
        }
        else
        {
          /*
           * Normalement, on n'a pas besoin de remettre mem[curr]
           * à NULL car on n'accèdera plus à cette case.
           */

          prev_slot_delta = (uint32_t) (prev_slot - kernel_allocator . base);
          kernel_allocator . base[prev_slot_delta] =
            kernel_allocator . base[slot_delta];
        }

        size_log += 1;
        stop_merge = false;

        if (address_base > buddy_addr)
        {
          address_base = buddy_addr;
        }
      }
    }
    while (!stop_merge);

    /*
     * Ajout en tête de la case libre pour cette taille.
     */

    temp = kernel_allocator . free[size_log];
    kernel_allocator . free[size_log] = address_base;
    kernel_allocator . base[address_delta] = (uint32_t) temp;

    lock_release (& kernel_allocator . lock);
    cpu_trap_restore(it_status);

    return status;
  }
}

/*
 ****/

