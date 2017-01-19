#include <stdio.h>
#include <stdint.h>
#include <stddef.h>

extern char sse42_enabled(void);
extern uint64_t* sse42_test(uint64_t rdi, uint64_t* array);

extern int sse42_strlen(char*);
extern int sse42_strcmp(char*, char* );
extern int sse42_strcmp_mask(char*, char* );
extern void sse42_rep(void*, void*, int);

extern uint64_t time(void (*func)());

/* Returns a byte mask */
extern int sse42_strstr_mask(char*, char* );


static uint64_t array1[0x1000];
static uint64_t array2[0x1000];

char* longstr = "The quick brown fox jumped over the lazy dog, who was laying in the sun getting a tan and my name is Michael abcedefghijklmnopqrstuvwxyajsjd92837";
char* shortstr = "Michael";

int test(void) 
{
	memcpy(array2, array1, 4096);
	
	return 0;// sse42_strlen(shortstr);
}


int test2(void) 
{

	sse42_rep(array2, array1, 4096);
	return 0;
}

int test3(void) 
{
	sse42_memcpy_aligned(array2, array1, 0x8000);
	return 0;
}

int main(void)
{
	
	printf("SSE4.2? %d %d bytes\n", sse42_enabled(), sizeof array1);


	char* s1 = "Hello, world!";
	char* s2 = "Hello, world!";
	printf("strlen: %d %d\n", sse42_strlen(longstr), strlen(longstr));

	printf("strcmp: %x\n", sse42_strcmp_mask(s1, s2));
	printf("strstr: %x\n", sse42_strstr_mask("eejellhelohehhehelohelohelohelohelo", "he"));


	uint8_t ar1[8] = { 1, 2, 3, 4, 5, 6, 7, 8};
	uint8_t ar2[8] = { 9, 8, 7, 6, 5, 4, 3, 2};

	sse42_test(ar1, ar2);
	for(int i = 0; i < 8; i++)
		printf("%d: %d\n", i, ar1[i]);


	memset(array1, 'A', 0x8000);
	uint64_t avg = 0;
	for(int j = 0; j < 24; j++) {
		uint64_t t1 = 0;
		for (int i = 0; i < 12; i++) {
			t1 += time(test);
		}
		t1 /= 12;
		if (j > 5)
			avg += t1;
	}
	printf("Builtin memcpy: 24 replicates of 12: Average clock cycles: %zd\n", (avg / 19));
	//printf("%zx, %zx", array2[1], array2[0xfff]);
	memset(array1, 'B', 0x8000);
	avg = 0;
	for(int j = 0; j < 24; j++) {
		uint64_t t1 = 0;
		for (int i = 0; i < 12; i++) {
			t1 += time(test2);
		}
		t1 /= 12;
		if (j > 5)
			avg += t1;

	}
	printf("Rep movsb: 24 replicates of 12: Average clock cycles: %zd\n", (avg / 19));
	//printf("%zx, %zx", array2[1], array2[0xfff]);
	avg = 0;
	memset(array1, 'C', 0x8000);
	for(int j = 0; j < 24; j++) {
		uint64_t t1 = 0;
		for (int i = 0; i < 12; i++) {
			t1 += time(test3);
		}
		t1 /= 12;
		if (j > 5)
			avg += t1;

	}
	printf("SSE aligned: 24 replicates of 12: Average clock cycles: %zd\n", (avg / 19));

	printf("%zx, %zx", array2[1], array2[0xfff]);
	for (int i = 0; i < 0x1000; i++) {
		if (array2[i] != array2[0]) {
			printf("stop at %x\n", i);
			break;
		}
	}

}