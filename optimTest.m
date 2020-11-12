
op = optimizer([10,-20,20;4,-10,10], @cost, @conv, 100, 100);
op.run(1);
