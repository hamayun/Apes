
#include <Private/SoclibBlockDeviceDriver.h>
#include <Core/Core.h>
#include <DnaTools/DnaTools.h>


status_t block_device_free (void * data)
{

  dna_printf("In block_device_free-------\n");

  return DNA_OK ;
}
