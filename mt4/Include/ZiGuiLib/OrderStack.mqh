//+------------------------------------------------------------------+
//|                                                   OrderStack.mqh |
//|                                  Copyright 2017, Katokunou Corp. |
//|                                             http://katokunou.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Katokunou Corp."
#property link      "https://katokunou.com"
#property version   "1.00"
#property strict

#include <ZiGuiLib\PositionType.mqh>

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class Order
  {
public:
    int orderId;
    Order* next;

    Order();
   ~Order();
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
Order::Order()
  {
    this.orderId = -1;
    this.next = NULL;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
Order::~Order()
  {
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class OrderStack
  {
private:
    int              size;
    Order*           head;
    void             pushOrder(int aOrderId);
    int              popOrder();
    PositionType     type;

public:
                     OrderStack(PositionType aType);
                    ~OrderStack();
    // 
    void             push(int aOrderId);
    //
    int              pop();
    //
    int              peek();
    //
    bool             empty();
    //
    int              search(int aOrderId);
    //
    int              length();
    //
    void             clear();
    //
    PositionType     getType();
    //
    void             display();
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
OrderStack::OrderStack(PositionType aType)
  {
    this.size = 0;
    this.head = NULL;
    this.type = aType;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
OrderStack::~OrderStack()
  {
    this.clear();
  }
//+------------------------------------------------------------------+
//| push an element into stack                                       |
//+------------------------------------------------------------------+
void OrderStack::pushOrder(int aOrderId)
  {
    Order* tmp = new Order();

    if (tmp == NULL) {
        return;
    }
    tmp.orderId = aOrderId;
    tmp.next = head;

    this.head = tmp;
    this.size++;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OrderStack::push(int aOrderId)
  {
    this.pushOrder(aOrderId);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OrderStack::popOrder()
  {
    int orderId = -1;
    Order* tmp = this.head;

    if (tmp != NULL) {
      orderId = tmp.orderId;

      this.head = tmp.next;
      delete tmp;
      this.size--;
    }

    return orderId;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OrderStack::pop()
  {
    return this.popOrder();
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OrderStack::peek()
  {
    int orderId = -1;

    if (!this.empty())
      orderId = this.head.orderId;

    return orderId;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool OrderStack::empty()
  {
    return this.head == NULL;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OrderStack::search(int aOrderId)
  {
    int idx = 0;
    Order* tmp = this.head;

    while (tmp != NULL && tmp.orderId != aOrderId) {
      idx++;
      tmp = tmp.next;
    }
    if (tmp == NULL)
      idx = -1;

    return idx;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OrderStack::length()
  {
    return this.size;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OrderStack::clear()
  {
    while (this.pop() != -1)
      this.pop();
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
PositionType OrderStack::getType()
  {
    return this.type;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OrderStack::display()
  {
    Order *current;
    current = this.head;
    if (current != NULL)
    {
        string text = "Stack";
        string stackType = " SHORT";
        if (this.type == LONG)
          stackType = " LONG ";

        text = StringConcatenate(text, " [", stackType ,"]");
        text = StringConcatenate(text, " [", IntegerToString(this.size) ,"]");
        do
        {
            text = StringConcatenate(text, " :: ", IntegerToString(current.orderId));
            current = current.next;
        }
        while (current != NULL);
        Print(text);
    }
    else
    {
        Print("The Stack is empty\n");
    }
  }
//+------------------------------------------------------------------+
