
#include <Private/SoclibBlockDeviceDriver.h>
#include <Core/Core.h>
#include <DnaTools/DnaTools.h>

status_t block_device_open (char * name, int32_t mode, void ** data)
{
  char * num = name + dna_strlen(name) -1;
  
  dna_printf("In block_device_open -------\n");

  block_device_control_t * block_device_p = &(block_device_controls[dna_atoi(num)]) ;
  *data = (void *) block_device_p ;
  return DNA_OK ;
}

