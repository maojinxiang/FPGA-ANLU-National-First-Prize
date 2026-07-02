-----------------------------------------------------
-- Company: anlgoic
-- Author: 	xg 
-----------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;



entity DVITransmitter is
	 Generic (FAMILY : STRING := "EG4");
	 
    Port ( RED_I : in  STD_LOGIC_VECTOR (7 downto 0);
           GREEN_I : in  STD_LOGIC_VECTOR (7 downto 0);
           BLUE_I : in  STD_LOGIC_VECTOR (7 downto 0);
           HS_I : in  STD_LOGIC;
           VS_I : in  STD_LOGIC;
           VDE_I : in  STD_LOGIC;
		   RST_I : in STD_LOGIC;
           PCLK_I : in  STD_LOGIC;
           PCLK_X5_I : in  STD_LOGIC;
           TMDS_TX_CLK_P : out  STD_LOGIC;
           TMDS_TX_2_P : out  STD_LOGIC;
           TMDS_TX_1_P : out  STD_LOGIC;
           TMDS_TX_0_P : out  STD_LOGIC		   
		   
		   );
end DVITransmitter;

`protect begin_protected
`protect version = 1
`protect encrypt_agent = "Anlogic"
`protect encrypt_agent_info = "Anlogic Encryption Tool anlogic_2019"
`protect key_keyowner = "Anlogic", key_keyname = "anlogic-rsa-002"
`protect key_method = "rsa"
`protect encoding = (enctype = "BASE64", line_length = 64, bytes = 128)
`protect key_block
MU4Uv3N+RR2LkyXZN3wb6Iaylnfz8KpfY7d2HoqSY6hfVCHf0eEU0HmTtvoGqYxx
Dak/tcX7FpszC1nOr48CA5JlOkBR/X6gwJXbkaeeM+gkv4fj1g10KO7a/Or+v/Gn
BKW7F6fZBzfDRK6ZhbHi7mh8czpgYO7/SFgNZIfr5lA=
`protect key_keyowner = "Cadence Design Systems.", key_keyname = "CDS_RSA_KEY_VER_1"
`protect key_method = "rsa"
`protect encoding = (enctype = "BASE64", line_length = 64, bytes = 256)
`protect key_block
FTHWs8fRspLdO/VZXcBHGSUEP1T5CHBUjnOrvwmfd1h1wI+WOzD6mJFOumQ9Lr/5
83KIwAp5iFjv6qpoFUoq4D7SGQMckDy8Za0QUvZIuVHElnNZoHfhnrkOMNDGoO8c
G3IBF8NM3DBbWpamVyCXAKVIgYZQR4pKril6OJ+U+SbyxD0XS7tx88HSK07CRQTC
UV8SLyfigiJiKd7ugbDzyDj4btNoDcS8iV4R6sropm4kMHZ+8umRt4HL8FcXFpem
zB0G+SD/dvMG9d79Xx8z3OsKLiATAq+3qhlTEpYCmnW8cRBQD0KVKl/M+plKHiTP
0xrSeLizKAeY7vdhUKU2eQ==
`protect key_keyowner = "Mentor Graphics Corporation", key_keyname = "MGC-VERIF-SIM-RSA-1"
`protect key_method = "rsa"
`protect encoding = (enctype = "BASE64", line_length = 64, bytes = 128)
`protect key_block
Mkn/sBlmGqI5BUlLT9vdzq0J3Gv32QFKM99pUKpRPGsXqfIm/Ua67ZTcwdrlXx0j
G3xU4kNY6v0WQKSFNYtgxaTFGJJ23InYElxaHhf4bsAjGe+53tC5MoS0sG2x06SA
TGJTYstNdrWsD6MsKHg/CkqnC4rGpVzUhtaL6308kVc=
`protect key_keyowner = "Mentor Graphics Corporation", key_keyname = "MGC-VERIF-SIM-RSA-2"
`protect key_method = "rsa"
`protect encoding = (enctype = "BASE64", line_length = 64, bytes = 256)
`protect key_block
m+qagpeGQqmHyB0WKv2lXF9fqFjlooYXMAZiRHRmKSi1r/kPpmQriC8SxT011uCR
MZV+ZIg7jH7JyGOvB2/UvRRY6wseqLHm90nQET225h9eEPkx31bo+y/4UMXu7ye3
unJuiygkA7mZTcn4mWPjsYAZltb7ZjESG9a7keasGa7+pt0gPp+nW6qsxUO7mFaY
j+iv53Kuarc29iVFq0rjr1YHesXIZ+b7A561nQpBDRY6G/NmqzZ+e9Tm774UnwU2
GDYJj/SHUU3BUH4Vaii9ZDkBHSIrqbFuUZJRuu2NRU4pijuo3ACKwRIj8+g5gjH6
6L4naPCSbCf1evH+LFX28w==
`protect key_keyowner = "Synopsys", key_keyname = "SNPS-VCS-RSA-2"
`protect key_method = "rsa"
`protect encoding = (enctype = "BASE64", line_length = 64, bytes = 128)
`protect key_block
GCGwJdiB8tJ03e9tNoac3mFYncIAjvuFGlFa9eg+dEIdWIlIbWNBsrRW9isOiGuk
Lte+EM42Ca5AXYsoLdBRPiq5Q6YxVWKqNXbiMeQFRI8bvKSvn8ZLPtQRzdOiMRk6
/R8F3vl0pMoH3b5fpRvFJ/rbQrMkbYVqbEqWPj7GPyU=
`protect data_method = "AES128-CBC"
`protect encoding = (enctype = "BASE64", line_length = 64, bytes = 4144)
`protect data_block
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
tZ73Bn87Q5sppJNqr0PU1g==
`protect end_protected


end Behavioral;

