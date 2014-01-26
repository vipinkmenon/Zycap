#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_BS_NUM 5

typedef struct bit_info{
        char name[128];
        int  size;
        int  addr;
        struct bit_info *prev;
        struct bit_info *next;
} bs_info;

int check_bs_present(bs_info *bs_list,char *bs_name)
{
    int i;
    for(i=0;i<MAX_BS_NUM;i++)
    {
        if(strcmp(bs_list[i].name,bs_name) == 0)
            return i;
    }
    return -1;
}

bs_info * init_bs_list(int num_bs)
{
    int i;
    bs_info *bs_list;
    bs_list = (bs_info *)malloc(num_bs*sizeof(bs_info));
    for(i=0;i<num_bs;i++)
    {
        strcpy(bs_list[i].name,"Dummy");
        bs_list[i].size = -1;
        bs_list[i].addr = -1;
        if(i==0)
            bs_list[i].prev = NULL;
        else
            bs_list[i].prev = &bs_list[i-1];
        if(i==num_bs-1)
            bs_list[i].next = NULL;
        else
            bs_list[i].next = &bs_list[i+1];
    }
    return bs_list;
}

void update_bs_list(bs_info *bs_list, bs_info bs)
{
    int bs_pres;
    int pres_first;
    int pres_last;
    bs_pres = check_bs_present(bs_list,bs.name);
    if (bs_pres != -1 && bs_list[bs_pres].prev != NULL)            //The bitstream is already in the list and is not the most recently used
    {
        bs_list[bs_pres].prev->next = bs_list[bs_pres].next;
        if(bs_list[bs_pres].next != NULL)
        {
            bs_list[bs_pres].next->prev = bs_list[bs_pres].prev;
        }
        pres_first = find_first_bs(bs_list);
        bs_list[bs_pres].prev = NULL;   
        bs_list[bs_pres].next = &bs_list[pres_first];
        bs_list[pres_first].prev = &bs_list[bs_pres];
    }
    else if(bs_pres == -1)
    {
        pres_last = find_last_bs(bs_list);
        pres_first = find_first_bs(bs_list);
        bs_list[pres_last].prev->next = NULL;   //make the second last element as the last element
        strcpy(bs_list[pres_last].name,bs.name);
        bs_list[pres_last].addr = bs.addr;
        bs_list[pres_last].size = bs.size;
        bs_list[pres_last].prev = NULL;
        bs_list[pres_last].next = &bs_list[pres_first];
        bs_list[pres_first].prev = &bs_list[pres_last];
    }
}

int find_first_bs(bs_info *bs_list)
{
    int i;
    for(i=0;i<MAX_BS_NUM;i++)
    {
        if(bs_list[i].prev == NULL)
            return i;
    }
}

int find_last_bs(bs_info *bs_list)
{
    int i;
    for(i=0;i<MAX_BS_NUM;i++)
    {
        if(bs_list[i].next== NULL)
            return i;
    }
}


void print_schedule(bs_info *bs_list)
{
    bs_info *current_bs;
    int i;
    for(i=0;i<MAX_BS_NUM;i++)
    {
        current_bs = &bs_list[i];
        printf("BS Num : %d BS Name : %s  BS Prev %s BS Next %s\n",i,current_bs->name,current_bs->prev,current_bs->next);
    }
}

int main(int argc, char *argv[])
{
    int i;
    char bs_name[128];
    bs_info *bs_list;
    bs_list = init_bs_list(MAX_BS_NUM);
    bs_info new_bs;
    while(1)
    {
        printf("Enter the file name : ");
        scanf("%s",bs_name);
        strcpy(new_bs.name,bs_name);
        new_bs.size = 0;
        new_bs.addr = 0;
        new_bs.prev = NULL;
        new_bs.next = NULL;
        update_bs_list(bs_list, new_bs);
        print_schedule(bs_list);
    }
    return 0;
}
