// Called from entry.S to get us going.
// entry.S already took care of defining envs, pages, vpd, and vpt.

#include <inc/lib.h>

extern void umain(int argc, char **argv);

const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.

	struct Env * envp= (struct Env*)envs;
	envid_t envid= sys_getenvid();
//   sys_cputs("sys_cputs curenv->env_id=%x\n", envid);


	while(envp < envs + NENV && envid != envp->env_id)
        envp++;

    if(envp >= envs + NENV){
       // sys_cputs("envp >= envs + NENV\n",30);
        sys_env_destroy(envid);
    }
    thisenv = envp;
  //  sys_cputs("if (argc > 0)\n",30);
	// save the name of the program so that panic() can use it
	if (argc > 0)
		binaryname = argv[0];
   // sys_cputs("umain(argc, argv)\n",30);
	// call user main routine
	umain(argc, argv);

	// exit gracefully
	exit();
}

