module Parser ( parser
              , Chunk (..)
              ) where

import Prelewd hiding (join)

import Data.Char
import Data.Maybe (catMaybes)
import Text.Parsec hiding ((<|>))
import Text.Parsec.String

type Data = Text
type Code = Text

data Chunk = Data Data
           | Code Code

-- end of input as a Monoid
end :: Monoid a => Parser a
end = eof $> mempty

-- `anyChar` as a singleton list
anyChars :: Parser [Char]
anyChars = anyChar <&> (:[])

infixl 6 `until`

until :: Monoid a => Parser a -> Parser a -> Parser a
until act s = end
            <|> try s $> mempty
            <|> act <&> (<>) <*> until act s

parser :: Parser [Chunk]
parser = catMaybes <$> sequence chunks `until` end

chunks :: [Parser (Maybe Chunk)]
chunks = [ make Data $ anyChars `until` string "{-@"
         , make Code $ anyChars `until` string "@-}"
         ]

make :: (Text -> Chunk) -> Parser Text -> Parser (Maybe Chunk)
make f = map $ bool Nothing <$> Just . f <*> not.null