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
#include <DnaTools/DnaTools.h>

driver_t soclib_platform_module = {
  "soclib_platform",
  soclib_platform_init_hardware,
  soclib_platform_init_driver,
  soclib_platform_uninit_driver,
  soclib_platform_publish_devices,
  soclib_platform_find_device
};

char ** soclib_platform_devices = NULL;

device_cmd_t soclib_tty_commands =
{
  soclib_tty_open,
  soclib_tty_close,
  soclib_tty_free,
  soclib_tty_read,
  soclib_tty_write,
  soclib_tty_control
};

