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

#include <Private/Driver.h>
#include <Core/Core.h>
#include <MemoryManager/MemoryManager.h>
#include <DnaTools/DnaTools.h>

soclib_tty_t * TTY = NULL;

status_t soclib_platform_init_driver (void)
{
  char alpha_index[8], sem_name[64];

  /*
   * Connect the TIMER and IPI ISRs.
   */

  for (int32_t i = 0; i < cpu_mp_count (); i += 1)
  {
    interrupt_attach (i, 0, 0x0, soclib_ipi_isr, true);
    interrupt_attach (i, 1, 0x0, soclib_timer_isr, false);
  }

  /*
   * Instantiate the TTY devices.
   */

  TTY = kernel_malloc (sizeof (soclib_tty_t) * SOCLIB_TTY_NDEV, true);
  if (TTY == NULL) return DNA_OUT_OF_MEM;

  for (int32_t i = 0; i < SOCLIB_TTY_NDEV; i += 1)
  {
    TTY[i] . irq = SOCLIB_TTY_DEVICES[i] . irq;
    TTY[i] . port = SOCLIB_TTY_DEVICES[i] . port;

    dna_itoa (i, alpha_index);
    dna_strcpy (sem_name, "soclib_tty_");
    dna_strcat (sem_name, alpha_index);
    dna_strcat (sem_name, "_sem");

    semaphore_create (sem_name, 0, & TTY[i] . sem_id);
    TTY[i] . buffer . empty = true;

    interrupt_attach (0, TTY[i] . irq, 0x0, soclib_tty_isr, false);
  }

  return DNA_OK;
}

