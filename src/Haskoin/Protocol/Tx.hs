module Haskoin.Protocol.Tx 
( Tx(..) 
, TxIn(..)
, TxOut(..)
, OutPoint(..)
, CoinbaseTx(..)
, txid
, encodeTxid
, decodeTxid
) where

import Control.Monad (replicateM, forM_, liftM2, unless)
import Control.Applicative ((<$>),(<*>))

import Data.Word (Word32, Word64)
import Data.Binary (Binary, get, put)
import Data.Binary.Get 
    ( getWord32le
    , getWord64le
    , getByteString
    , skip
    )
import Data.Binary.Put 
    ( putWord32le
    , putWord64le
    , putByteString
    )
import qualified Data.ByteString as BS 
    ( ByteString
    , length
    , reverse
    )

import Haskoin.Protocol.VarInt
import Haskoin.Protocol.Script
import Haskoin.Crypto (Hash256, doubleHash256)
import Haskoin.Util (bsToHex, hexToBS, encode', decodeToMaybe)

data Tx = Tx 
    { txVersion  :: !Word32
    , txIn       :: ![TxIn]
    , txOut      :: ![TxOut]
    , txLockTime :: !Word32
    } deriving (Eq, Show)

instance Binary Tx where

    get = Tx <$> getWord32le
             <*> (replicateList =<< get)
             <*> (replicateList =<< get)
             <*> getWord32le
        where replicateList (VarInt c) = replicateM (fromIntegral c) get

    put (Tx v is os l) = do
        putWord32le v
        put $ VarInt $ fromIntegral $ length is
        forM_ is put
        put $ VarInt $ fromIntegral $ length os
        forM_ os put
        putWord32le l

data CoinbaseTx = CoinbaseTx 
    { cbVersion  :: !Word32
    , cbData     :: !BS.ByteString
    , cbOut      :: ![TxOut]
    , cbLockTime :: !Word32
    } deriving (Eq, Show)

instance Binary CoinbaseTx where

    get = CoinbaseTx <$> getWord32le
                     <*> (readCoinbase  =<< get)
                     <*> (replicateList =<< get)
                     <*> getWord32le
        where 
            readCoinbase (VarInt in_size) = do
                skip 36 -- skip OutPoint
                (VarInt len)   <- get
                coinbase       <- getByteString (fromIntegral len)
                skip 4  -- skip sequence
                return coinbase
            replicateList (VarInt c) = replicateM (fromIntegral c) get

    put (CoinbaseTx v cb os l) = do
        putWord32le v
        put $ VarInt 1
        put $ OutPoint 0 maxBound
        put $ VarInt $ fromIntegral $ BS.length cb
        putByteString cb 
        putWord32le 0 --sequence number
        put $ VarInt $ fromIntegral $ length os
        forM_ os put
        putWord32le l

data TxIn = TxIn 
    { prevOutput   :: !OutPoint
    , scriptInput  :: !Script
    , txInSequence :: !Word32
    } deriving (Eq, Show)

instance Binary TxIn where
    get = TxIn <$> get <*> get <*> getWord32le
    put (TxIn o s seq) = put o >> put s >> putWord32le seq

data TxOut = TxOut 
    { outValue     :: !Word64
    , scriptOutput :: !Script
    } deriving (Eq, Show)

instance Binary TxOut where
    get = do
        val <- getWord64le
        unless (val <= 2100000000000000) $ fail $
            "Invalid TxOut value: " ++ (show val)
        TxOut val <$> get
    put (TxOut o s) = putWord64le o >> put s

data OutPoint = OutPoint 
    { outPointHash  :: !Hash256
    , outPointIndex :: !Word32
    } deriving Eq

instance Show OutPoint where
    show (OutPoint h i) = show ("txid = " ++ h',"index = " ++ (show i))
        where h' = encodeTxid h

instance Binary OutPoint where
    get = do
        (h,i) <- liftM2 (,) get getWord32le
        unless (i <= 2147483647) $ fail $
            "Invalid OutPoint index: " ++ (show i)
        return $ OutPoint h i
    put (OutPoint h i) = put h >> putWord32le i

txid :: Tx -> Hash256
txid = doubleHash256 . encode' 

-- |Encodes a transaction ID as little endian in HEX format
encodeTxid :: Hash256 -> String
encodeTxid = bsToHex . BS.reverse .  encode' 

decodeTxid :: String -> Maybe Hash256
decodeTxid = (decodeToMaybe . BS.reverse =<<) . hexToBS

