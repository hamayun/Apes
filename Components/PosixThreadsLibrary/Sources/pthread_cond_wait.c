#include <Private/PosixThreads.h>

int pthread_cond_wait (pthread_cond_t *condition, pthread_mutex_t *mutex)
{
  status_t status = DNA_OK;

  status = semaphore_acquire (condition -> semaphore, 1, DNA_RELATIVE_TIMEOUT, 0);

  if (status == DNA_WOULD_BLOCK)
  {
    condition -> count += 1;
    pthread_mutex_unlock (mutex);

    status = semaphore_acquire (condition -> semaphore, 1, 0, -1);
    pthread_mutex_lock (mutex);

    condition -> count -= 1;
  }

  return 0;
}

