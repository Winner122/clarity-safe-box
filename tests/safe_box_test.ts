import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Can register a document and verify ownership",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const docHash = '0x1234567890123456789012345678901234567890123456789012345678901234';
        
        let block = chain.mineBlock([
            Tx.contractCall('safe-box', 'register-document', [
                types.buff(docHash),
                types.ascii("Test Document"),
                types.ascii("Test Description")
            ], deployer.address)
        ]);
        
        block.receipts[0].result.expectOk().expectBool(true);
        
        let getDoc = chain.mineBlock([
            Tx.contractCall('safe-box', 'get-document', [
                types.buff(docHash)
            ], deployer.address)
        ]);
        
        getDoc.receipts[0].result.expectOk().expectTuple();
    }
});

Clarinet.test({
    name: "Can grant and revoke access to documents",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;
        const docHash = '0x1234567890123456789012345678901234567890123456789012345678901234';
        
        // Register document
        let block = chain.mineBlock([
            Tx.contractCall('safe-box', 'register-document', [
                types.buff(docHash),
                types.ascii("Test Document"),
                types.ascii("Test Description")
            ], deployer.address)
        ]);
        
        // Grant access
        block = chain.mineBlock([
            Tx.contractCall('safe-box', 'grant-access', [
                types.buff(docHash),
                types.principal(wallet1.address)
            ], deployer.address)
        ]);
        
        block.receipts[0].result.expectOk().expectBool(true);
        
        // Verify access
        let checkAccess = chain.mineBlock([
            Tx.contractCall('safe-box', 'has-access', [
                types.buff(docHash),
                types.principal(wallet1.address)
            ], deployer.address)
        ]);
        
        assertEquals(checkAccess.receipts[0].result, types.bool(true));
        
        // Revoke access
        block = chain.mineBlock([
            Tx.contractCall('safe-box', 'revoke-access', [
                types.buff(docHash),
                types.principal(wallet1.address)
            ], deployer.address)
        ]);
        
        block.receipts[0].result.expectOk().expectBool(true);
        
        // Verify access revoked
        checkAccess = chain.mineBlock([
            Tx.contractCall('safe-box', 'has-access', [
                types.buff(docHash),
                types.principal(wallet1.address)
            ], deployer.address)
        ]);
        
        assertEquals(checkAccess.receipts[0].result, types.bool(false));
    }
});

Clarinet.test({
    name: "Can update document and track versions",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const oldHash = '0x1234567890123456789012345678901234567890123456789012345678901234';
        const newHash = '0x1234567890123456789012345678901234567890123456789012345678901235';
        
        // Register initial document
        let block = chain.mineBlock([
            Tx.contractCall('safe-box', 'register-document', [
                types.buff(oldHash),
                types.ascii("Test Document"),
                types.ascii("Test Description")
            ], deployer.address)
        ]);
        
        // Update document
        block = chain.mineBlock([
            Tx.contractCall('safe-box', 'update-document', [
                types.buff(oldHash),
                types.buff(newHash),
                types.ascii("Updated Document"),
                types.ascii("Updated Description")
            ], deployer.address)
        ]);
        
        block.receipts[0].result.expectOk().expectBool(true);
        
        // Check version
        let version = chain.mineBlock([
            Tx.contractCall('safe-box', 'get-document-version', [
                types.buff(newHash)
            ], deployer.address)
        ]);
        
        assertEquals(version.receipts[0].result, types.uint(1));
    }
});