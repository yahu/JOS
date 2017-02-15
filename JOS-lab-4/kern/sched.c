#include <inc/assert.h>

#include <kern/env.h>
#include <kern/pmap.h>
#include <kern/monitor.h>


// Choose a user environment to run and run it.
void
sched_yield(void)
{
	struct Env *idle;
	int i,initpos;

	// Implement simple round-robin scheduling.
	//
	// Search through 'envs' for an ENV_RUNNABLE environment in
	// circular fashion starting just after the env this CPU was
	// last running.  Switch to the first such environment found.
	//
	// If no envs are runnable, but the environment previously
	// running on this CPU is still ENV_RUNNING, it's okay to
	// choose that environment.
	//
	// Never choose an environment that's currently running on
	// another CPU (env_status == ENV_RUNNING) and never choose an
	// idle environment (env_type == ENV_TYPE_IDLE).  If there are
	// no runnable environments, simply drop through to the code
	// below to switch to this CPU's idle environment.

	// LAB 4: Your code here.

	if(!curenv){
	    goto curenv0;
	}


    initpos = curenv - envs;
   // i=(initpos + 1)%NENV;

   // cprintf("in sched,current env [%x] 's status is %x\n ",curenv->env_id,curenv->env_status);

    if(curenv->env_status == ENV_RUNNING)
        curenv->env_status = ENV_RUNNABLE;

    for(i=(initpos + 1)%NENV;i != initpos;i = (i+1) % NENV){

       // cprintf("in sched,NENV=%x,initpos =%x,i=%x,(i+1) % NENV=%x\n",NENV,initpos,i,(i+1) % NENV);
        if(envs[i].env_type == ENV_TYPE_IDLE)
            continue;
        if(envs[i].env_status == ENV_RUNNABLE)
            break;

    }

    if(envs[i].env_type != ENV_TYPE_IDLE && envs[i].env_status == ENV_RUNNABLE){

       // cprintf("choose %x,its status is %x\n",envs[i].env_id,envs[i].env_status);
        envs[i].env_status = ENV_RUNNING;
        env_run(&envs[i]);
    }


	// For debugging and testing purposes, if there are no
	// runnable environments other than the idle environments,
	// drop into the kernel monitor.

	for (i = 0; i < NENV; i++) {
		if (envs[i].env_type != ENV_TYPE_IDLE &&
		    (envs[i].env_status == ENV_RUNNABLE ||
		     envs[i].env_status == ENV_RUNNING))
			break;
	}

	if (i == NENV) {
		cprintf("No more runnable environments!\n");
		while (1)
			monitor(NULL);
	}


	// Run this CPU's idle environment when nothing else is runnable.
curenv0:
	idle = &envs[cpunum()];
	if (!(idle->env_status == ENV_RUNNABLE || idle->env_status == ENV_RUNNING)){
	    panic("CPU %d: No idle environment!", cpunum());
	}
	curenv=idle;
	env_run(idle);
}
