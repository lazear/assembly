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


struct vector {
	float x;
	float y;
	float z;
	float pad;
};


/* Scalar operations */
extern struct vector* vector_adds(struct vector* dest, float f);
extern struct vector* vector_subs(struct vector* dest, float f);
extern struct vector* vector_muls(struct vector* dest, float f);
extern struct vector* vector_divs(struct vector* dest, float f);

/* Vector/Vector operations */
extern struct vector* vector_add(struct vector* dest, struct vector* source);
extern struct vector* vector_div(struct vector* dest, struct vector* source);
extern struct vector* vector_mul(struct vector* dest, struct vector* source);
extern struct vector* vector_sq(struct vector* dest);
extern struct vector* vector_sqrt(struct vector* dest);
extern float vector_magnitude(struct vector* dest);

void vector_print(struct vector* v)
{
	printf("x %f y %f z %f p %f\n", v->x, v->y, v->z, v->pad);
}

int main(void)
{
	
	printf("SSE4.2? %d %zd bytes\n", sse42_enabled(), sizeof array1);
	struct vector a, b;
	a.x = 10.2;
	a.y = 7.3;
	a.z = 12.1;

	b.x = 91;
	b.y = 144;
	b.z = 49;

	//vector_mul(&a, vector_add(&b, &b));
	
	printf("%f\n", (vector_magnitude(&a)));
	vector_print(vector_sqrt(&b));
	float f = 7.9;
	vector_print(vector_adds(&a, f));
}