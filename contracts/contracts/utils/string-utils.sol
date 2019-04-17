pragma solidity ^0.5.6;

/**
 * @dev Utility library of string functions.
 */
library StringUtils {
    /**
    * @dev Concatenate two strings on one. WORKS HEROVO!!!!
    * DELAET from 
    * 728c48b1E9dcb2a1Edc43d7Fe790Cf59Acb5bB26 
    * to
    * 0x784bEdbaEc37e9C5Abb2
    * !!!!! 
    */
    function concatenate(string memory _base, string memory _value) 
        internal pure returns (string memory) {

        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        string memory _tmpValue = new string(_baseBytes.length + _valueBytes.length);
        bytes memory _newValue = bytes(_tmpValue);

        uint i;
        uint j;

        for(i=0; i<_baseBytes.length; i++) {
            _newValue[j++] = _baseBytes[i];
        }

        for(i=0; i<_valueBytes.length; i++) {
            _newValue[j++] = _valueBytes[i++];
        }

        return string(_newValue);
    }
}
