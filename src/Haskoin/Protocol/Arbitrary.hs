module Haskoin.Protocol.Arbitrary () where

import Test.QuickCheck
import Haskoin.Util.Arbitrary (nonEmptyBS)
import Haskoin.Crypto.Arbitrary

import Control.Monad
import Control.Applicative 

import Haskoin.Protocol
import Haskoin.Crypto
import Haskoin.Util 

instance Arbitrary VarInt where
    arbitrary = VarInt <$> arbitrary

instance Arbitrary VarString where
    arbitrary = VarString <$> arbitrary

instance Arbitrary NetworkAddress where
    arbitrary = do
        s <- arbitrary
        a <- liftM2 (,) arbitrary arbitrary
        p <- arbitrary
        return $ NetworkAddress s a p

instance Arbitrary InvType where
    arbitrary = elements [InvError, InvTx, InvBlock]

instance Arbitrary InvVector where
    arbitrary = InvVector <$> arbitrary <*> (hash256 <$> arbitrary)

instance Arbitrary Inv where
    arbitrary = Inv <$> listOf arbitrary

instance Arbitrary Version where
    arbitrary = Version <$> arbitrary
                        <*> arbitrary
                        <*> arbitrary
                        <*> arbitrary
                        <*> arbitrary
                        <*> arbitrary
                        <*> arbitrary
                        <*> arbitrary
                        <*> arbitrary

instance Arbitrary Addr where
    arbitrary = Addr <$> listOf arbitrary

instance Arbitrary Alert where
    arbitrary = Alert <$> arbitrary <*> arbitrary

instance Arbitrary BlockHeader where
    arbitrary = BlockHeader <$> arbitrary
                            <*> (hash256 <$> arbitrary)
                            <*> (hash256 <$> arbitrary)
                            <*> arbitrary
                            <*> arbitrary
                            <*> arbitrary
                            
instance Arbitrary Script where
    arbitrary = do
        i <- choose (1,10)
        Script <$> (vectorOf i arbitrary)

instance Arbitrary Tx where
    arbitrary = do
        v   <- arbitrary
        tin <- do 
            l <- choose (0,10)
            vectorOf l arbitrary
        tout <- do
            l <- choose (0,10)
            vectorOf l arbitrary
        t    <- arbitrary
        return $ Tx v tin tout t

instance Arbitrary CoinbaseTx where
    arbitrary = CoinbaseTx <$> arbitrary
                           <*> arbitrary
                           <*> (listOf arbitrary)
                           <*> arbitrary

instance Arbitrary TxIn where
    arbitrary = TxIn <$> arbitrary
                     <*> arbitrary
                     <*> arbitrary

instance Arbitrary TxOut where
    arbitrary = TxOut <$> arbitrary
                      <*> arbitrary

instance Arbitrary OutPoint where
    arbitrary = OutPoint <$> (hash256 <$> arbitrary)
                         <*> arbitrary

instance Arbitrary Block where
    arbitrary = do
        h <- arbitrary
        c <- arbitrary
        t <- do 
            l <- choose (0,10)
            vectorOf l arbitrary
        return $ Block h c t

instance Arbitrary ScriptOp where
    arbitrary = oneof [ OP_PUSHDATA <$> nonEmptyBS
                      , return OP_FALSE
                      , return OP_1NEGATE
                      , return OP_1
                      , return OP_2, return OP_3, return OP_4, return OP_5
                      , return OP_6, return OP_7, return OP_8, return OP_9
                      , return OP_10, return OP_11, return OP_12, return OP_13
                      , return OP_14, return OP_15, return OP_16
                      , return OP_VERIFY
                      , return OP_DUP
                      , return OP_EQUAL
                      , return OP_EQUALVERIFY
                      , return OP_HASH160
                      , return OP_CHECKSIG
                      , return OP_CHECKMULTISIG
                      , OP_PUBKEY <$> arbitrary
                      , return $ OP_INVALIDOPCODE 0xff
                      ]

instance Arbitrary GetBlocks where
    arbitrary = GetBlocks <$> arbitrary
                          <*> (listOf (hash256 <$> arbitrary))
                          <*> (hash256 <$> arbitrary)

instance Arbitrary GetData where
    arbitrary = GetData <$> (listOf arbitrary)

instance Arbitrary GetHeaders where
    arbitrary = GetHeaders <$> arbitrary
                           <*> (listOf (hash256 <$> arbitrary))
                           <*> (hash256 <$> arbitrary)

instance Arbitrary Headers where
    arbitrary = Headers <$> (listOf (liftM2 (,) arbitrary arbitrary))

instance Arbitrary NotFound where
    arbitrary = NotFound <$> (listOf arbitrary)

instance Arbitrary Ping where
    arbitrary = Ping <$> arbitrary

instance Arbitrary Pong where
    arbitrary = Pong <$> arbitrary

instance Arbitrary MessageCommand where
    arbitrary = elements [ MCVersion
                         , MCVerAck
                         , MCAddr
                         , MCInv
                         , MCGetData
                         , MCNotFound
                         , MCGetBlocks
                         , MCGetHeaders
                         , MCTx
                         , MCBlock
                         , MCHeaders
                         , MCGetAddr
                         , MCPing
                         , MCPong
                         , MCAlert
                         ]

instance Arbitrary MessageHeader where
    arbitrary = MessageHeader <$> arbitrary
                              <*> arbitrary
                              <*> arbitrary
                              <*> (chksum32 <$> arbitrary)

instance Arbitrary Message where
    arbitrary = oneof [ MVersion <$> arbitrary
                      , return MVerAck
                      , MAddr <$> arbitrary
                      , MInv <$> arbitrary
                      , MGetData <$> arbitrary
                      , MNotFound <$> arbitrary
                      , MGetBlocks <$> arbitrary
                      , MGetHeaders <$> arbitrary
                      , MTx <$> arbitrary
                      , MBlock <$> arbitrary
                      , MHeaders <$> arbitrary
                      , return MGetAddr
                      , MPing <$> arbitrary
                      , MPong <$> arbitrary
                      , MAlert <$> arbitrary
                      ]
