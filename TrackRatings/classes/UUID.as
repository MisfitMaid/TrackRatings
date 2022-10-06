// adapted from https://gitlab.com/-/snippets/2068300

/**
 * Ported from <https://github.com/uuidjs/uuid>.
 *
 * Example usage:
 * ```
 * string test = UUID::stringify(UUID::V4::generate());
 * println( test );
 * println( UUID::validate(test) ? "TRUE" : "FALSE" );
 * println( UUID::version(test) );
 * ```
 */
namespace UUID {
    namespace V4 {
        /**
         * type: RNGFuncDef
         *
         * --- C++
         * funcdef uint8[] UUID::V4::RNGFuncDef();
         * ---
         *
         * RNG function definition.
         */
        funcdef uint8[] RNGFuncDef();

        /**
         * method: generate
         *
         * Create an RFC version 4 (random) UUID.
         *
         * Parameters:
         * rngFunc  - Random number generator function to use for (Default = <UUID::rng>).
         *
         * Returns:
         * uint8[]  - Array of UUID.
         */
        uint8[] generate (RNGFuncDef@ rngFunc = rng)
        {
            uint8[] rnds = rngFunc();

            // Per 4.4, set bits for version and `clock_seq_hi_and_reserved`.
            rnds[6] = (rnds[6] & 0x0f) | 0x40;
            rnds[8] = (rnds[8] & 0x3f) | 0x80;

            return rnds;
        }
    }

    // Random Number Generator.
    uint8[] rnds8Pool(256); // # of random values to pre-allocate.
    uint poolPtr = rnds8Pool.Length;
    uint8[] rng ()
    {
        const uint len = rnds8Pool.Length;
        if (poolPtr > len - 16) {
            for (uint i = 0; i < len; i++)
                rnds8Pool[i] = uint8(Math::Rand(0, 255));
            poolPtr = 0;
        }
        uint8[] result();
        for (uint xxx = poolPtr + 16; poolPtr < xxx; poolPtr++) result.InsertLast( rnds8Pool[poolPtr] );

        return result;
    }

    string stringify (uint8[] arr, uint offset = 0)
    {
        string uuid = formatUInt(arr[offset + 0]) +
            formatUInt(arr[offset + 1]) +
            formatUInt(arr[offset + 2]) +
            formatUInt(arr[offset + 3]) +
            formatUInt(arr[offset + 4]) +
            formatUInt(arr[offset + 5]) +
            formatUInt(arr[offset + 6]) +
            formatUInt(arr[offset + 7]) +
            formatUInt(arr[offset + 8]) +
            formatUInt(arr[offset + 9]) +
            formatUInt(arr[offset + 10]) +
            formatUInt(arr[offset + 11]) +
            formatUInt(arr[offset + 12]) +
            formatUInt(arr[offset + 13]) +
            formatUInt(arr[offset + 14]) +
            formatUInt(arr[offset + 15]);

        return uuid;
    }

    // cant be bothered to find-replace the above functions
    string formatUInt(uint8 value) {
        return Text::Format("%02x", value);
    }
}
