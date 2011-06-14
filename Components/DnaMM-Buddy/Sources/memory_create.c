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

#include <Private/MemoryManager.h>
#include <DnaTools/DnaTools.h>

/****f* framework/memory_create
 * SUMMARY
 * Create the memory component.
 *
 * SYNOPSIS
 */

status_t memory_create (void)

/*
 * FUNCTION
 * - Initializes the BSS.
 * - Initializes each member of the memory manager element.
 * - Initializes the kernel allocator.
 *
 * SOURCE
 */

{
  uint32_t bss_size = 0;

  /*
   * Initializes the BSS to 0
   */

  bss_size = (size_t) (CPU_BSS_END - CPU_BSS_START);
  dna_memset ((void *) CPU_BSS_START, 0, bss_size);

  /*
   * Initializes the kernel allocator
   */

  kernel_allocator . lock = 0;
  kernel_allocator . base = (uint32_t *)OS_KERNEL_HEAP_ADDRESS;
  dna_memset (kernel_allocator . free, 0, sizeof (kernel_allocator . free));
  kernel_allocator . free[DNA_MM_MAX_POW2_INDEX] = OS_KERNEL_HEAP_ADDRESS;

  return DNA_OK;
}

/*
 ****/

