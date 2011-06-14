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

#include <Private/VirtualFileSystem.h>
#include <Core/Core.h>
#include <DnaTools/DnaTools.h>
#include <Processor/Processor.h>

/****f* Operation/vfs_lseek
 * SUMMARY
 * Reposition the offset of an opened file.
 *
 * SYNOPSIS
 */

status_t vfs_lseek (int16_t fd, int64_t offset, int32_t whence, int64_t * p_ret)

/*
 * ARGUMENTS
 * * fd : the identifier of the file.
 * * offset : the required offset
 * * whence : the directive
 * * p_ret : the return value
 *
 * FUNCTION
 * Relocate the position pointer of the file corresponding to the file
 * descriptor FD.
 *
 * RESULT
 * * DNA_INVALID_FD : the file descriptor fd does not exist
 * * DNA_INVALID_WHENCE : the whence value is not valid
 * * DNA_ERROR : an error occured while getting or releasing the file
 * * DN_OK : the operation succeeded
 *
 * SOURCE
 */

{
  file_t file = NULL;
  status_t status = DNA_OK;
  interrupt_status_t it_status = 0;

  watch (status_t)
  {
    ensure (fd >= 0 && fd < DNA_MAX_FILE, DNA_INVALID_FD);
    ensure (whence == DNA_SEEK_SET ||
        whence == DNA_SEEK_FROM_CURRENT, DNA_INVALID_WHENCE);

    /*
     * Get the file associated to the fd.
     */

    status = file_get (fd, & file);
    ensure (status == DNA_OK, status);

    /*
     * Check the seek whence operator.
     */

    it_status = cpu_trap_mask_and_backup();
    lock_acquire (& file -> lock);

    switch (whence)
    {
      case DNA_SEEK_SET :
        file -> offset = offset;
        break;

      case DNA_SEEK_FROM_CURRENT :
        file -> offset += offset;
        break;
    }

    /*
     * Update the offset, release the file, and return.$
     */

    lock_release (& file -> lock);
    cpu_trap_restore(it_status);
    
    *p_ret = file -> offset;

    status = file_put (fd);
    panic (status != DNA_OK);

    return DNA_OK;
  }
}

/*
 ****/

