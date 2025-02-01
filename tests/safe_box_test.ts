import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

// Previous tests remain...

Clarinet.test({
    name: "Can register encrypted document and manage access",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;
        const docHash = '0x1234567890123456789012345678901234567890123456789012345678901234';
        const encKey = '0x0000000000000000000000000000000000000000000000000000000000000001';
        
        let block = chain.mineBlock([
            Tx.contractCall('safe-box', 'register-document', [
                types.buff(docHash),
                types.ascii("Encrypted Document"),
                types.ascii("Test Description"),
                types.some(types.buff(encKey))
            ], deployer.address)
        ]);
        
        block.receipts[0].result.expectOk().expectBool(true);
        
        // Grant access with encryption key
        block = chain.mineBlock([
            Tx.contractCall('safe-box', 'grant-access', [
                types.buff(docHash),
                types.principal(wallet1.address),
                types.some(types.buff(encKey))
            ], deployer.address)
        ]);
        
        block.receipts[0].result.expectOk().expectBool(true);
    }
});

Clarinet.test({
    name: "Can create and manage sharing groups",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;
        const wallet2 = accounts.get('wallet_2')!;
        const groupId = '0x1111111111111111111111111111111111111111111111111111111111111111';
        
        let block = chain.mineBlock([
            Tx.contractCall('safe-box', 'create-sharing-group', [
                types.buff(groupId),
                types.ascii("Test Group"),
                types.list([
                    types.principal(wallet1.address),
                    types.principal(wallet2.address)
                ])
            ], deployer.address)
        ]);
        
        block.receipts[0].result.expectOk().expectBool(true);
    }
});
