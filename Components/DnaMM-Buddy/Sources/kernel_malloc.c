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

/**** kernel/kernel_malloc
 * SUMMARY
 * Fast malloc for the kernel.
 *
 * SYNOPSIS
 */

void * kernel_malloc (uint32_t size, bool erase)

/*
 * ARGUMENTS
 * * size : the amount of memory to create, in bytes
 *
 * RESULT
 * * A valid data pointer in case of success.
 * * NULL in case of failure.
 *
 * SOURCE
 */

{
  void * area = NULL;
  uint32_t size_log, size_4octets, slot, address_delta = 0, buddy_delta;
  uint32_t * address_base, * buddy_addr, * temp;
  interrupt_status_t it_status = 0;

  watch (void *)
  {
    ensure (size != 0, NULL);

    /*
     * Enter a critical section to avoid concurrency issues.
     */

    it_status = cpu_trap_mask_and_backup();
    lock_acquire (& kernel_allocator . lock);

    /*
     * Compute variables related to the requested size.
     */

    size_4octets = (size + 4) >> 2;
    size_4octets += (size_4octets << 2) != size + 4 ? 1 : 0;
    check (create_failed, size_4octets <= OS_KERNEL_HEAP_SIZE >> 2, NULL);

    size_log = dna_log2 (size_4octets);
    size_log += size_4octets != (1 << size_log) ? 1 : 0;

    if (kernel_allocator . free[size_log] == NULL)
    {
      for (slot = size_log; slot < DNA_MM_MAX_POW2_INDEX + 1 &&
          kernel_allocator . free[slot] == NULL; slot += 1);
      check (create_failed, slot != DNA_MM_MAX_POW2_INDEX + 1, NULL);

      /*
       * On supprime l'adresse allouée des cases libres.
       */

      address_base = kernel_allocator . free[slot];
      address_delta = (uint32_t) (address_base - kernel_allocator . base);

      kernel_allocator . free[slot] =
        (uint32_t *) kernel_allocator . base[address_delta];
      slot -= 1;

      while (slot != size_log - 1)
      {
        buddy_delta = address_delta ^ (1 << slot);
        buddy_addr = kernel_allocator . base + buddy_delta ;

        if (kernel_allocator . free[slot] == NULL)
        {
          kernel_allocator . free[slot] = buddy_addr;
          kernel_allocator . base[buddy_delta] = (uint32_t) NULL;
        }
        else
        {
          temp = kernel_allocator . free[slot];
          kernel_allocator . free[slot] = buddy_addr;
          kernel_allocator . base[buddy_delta] = (uint32_t) temp;
        }

        slot -= 1;
      }
    }
    else
    {
      /*
       * On supprime l'adresse allouée des cases libres.
       */

      address_base = kernel_allocator . free[size_log];
      address_delta = (uint32_t) (address_base - kernel_allocator . base);
      kernel_allocator . free[size_log] =
        (uint32_t *) kernel_allocator . base[address_delta];
    }

    /*
     * Configure the allocated area.
     */

    address_base[0] = size + 4;
    area = & address_base[1];

    /*
     * Leave the critical section and check if we need to erase
     * the allocated area.
     */

    lock_release (& kernel_allocator . lock);
    cpu_trap_restore(it_status);

    if (erase)
    {
      dna_memset (area, 0, size_4octets * sizeof (uint32_t));
    }

    return area;
  }

  rescue (create_failed)
  {
    lock_release (& kernel_allocator . lock);
    cpu_trap_restore(it_status);
    leave;
  }
}

/*
 ****/

