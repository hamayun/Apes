#include <Private/PosixThreads.h>

int pthread_mutex_unlock (pthread_mutex_t *mutex)
{
  if (mutex == NULL) return EFAULT;
  if (mutex -> lock == -1) return EINVAL;

  mutex -> status = MUTEX_UNLOCKED;
  semaphore_release (mutex -> lock, 1, 0);

  return 0;
}
