import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Cannot create group with empty member list",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const groupId = '0x1111111111111111111111111111111111111111111111111111111111111111';
        
        let block = chain.mineBlock([
            Tx.contractCall('safe-box', 'create-sharing-group', [
                types.buff(groupId),
                types.ascii("Test Group"),
                types.list([])
            ], deployer.address)
        ]);
        
        block.receipts[0].result.expectErr().expectUint(105);
    }
});

Clarinet.test({
    name: "Cannot grant duplicate access to group members",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;
        const groupId = '0x1111111111111111111111111111111111111111111111111111111111111111';
        const docHash = '0x2222222222222222222222222222222222222222222222222222222222222222';
        const encKey = '0x3333333333333333333333333333333333333333333333333333333333333333';
        
        // Setup initial access
        let block = chain.mineBlock([
            Tx.contractCall('safe-box', 'register-document', [
                types.buff(docHash),
                types.ascii("Test Document"),
                types.ascii("Description"),
                types.some(types.buff(encKey))
            ], deployer.address),
            Tx.contractCall('safe-box', 'create-sharing-group', [
                types.buff(groupId),
                types.ascii("Test Group"),
                types.list([types.principal(wallet1.address)])
            ], deployer.address),
            Tx.contractCall('safe-box', 'grant-group-access', [
                types.buff(docHash),
                types.buff(groupId),
                types.some(types.buff(encKey))
            ], deployer.address)
        ]);
        
        // Try granting access again
        block = chain.mineBlock([
            Tx.contractCall('safe-box', 'grant-group-access', [
                types.buff(docHash),
                types.buff(groupId),
                types.some(types.buff(encKey))
            ], deployer.address)
        ]);
        
        block.receipts[0].result.expectErr().expectUint(106);
    }
});
