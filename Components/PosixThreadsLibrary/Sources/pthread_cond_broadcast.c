#include <Private/PosixThreads.h>

int pthread_cond_broadcast(pthread_cond_t *condition)
{
  status_t status = DNA_OK;

  if (condition -> count > 0)
  {
    status = semaphore_release (condition -> semaphore,
        condition -> count, 0);
    if (status == DNA_BAD_SEM_ID) return EINVAL;
  }

  return 0;
}
