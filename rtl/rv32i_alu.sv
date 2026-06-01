// =============================================================================
// RISC-V RV32I ALU
// Supports base integer arithmetic and logic operations
// =============================================================================

module rv32i_alu (
    input  logic [31:0] operand_a,
    input  logic [31:0] operand_b,
    input  logic [3:0]  alu_op,
    output logic [31:0] result,
    output logic        zero_flag,
    output logic        overflow_flag,
    output logic        carry_flag,
    output logic        negative_flag
);

    // ALU Operation Encoding (matches RISC-V funct3 + funct7 mapping)
    typedef enum logic [3:0] {
        ALU_ADD  = 4'b0000,  // Addition
        ALU_SUB  = 4'b0001,  // Subtraction
        ALU_AND  = 4'b0010,  // Bitwise AND
        ALU_OR   = 4'b0011,  // Bitwise OR
        ALU_XOR  = 4'b0100,  // Bitwise XOR
        ALU_SLL  = 4'b0101,  // Shift Left Logical
        ALU_SRL  = 4'b0110,  // Shift Right Logical
        ALU_SRA  = 4'b0111,  // Shift Right Arithmetic
        ALU_SLT  = 4'b1000,  // Set Less Than (signed)
        ALU_SLTU = 4'b1001   // Set Less Than (unsigned)
    } alu_op_e;

    // Internal signals
    logic [32:0] add_result;
    logic [32:0] sub_result;
    logic        signed_overflow;

    // Addition and subtraction with carry
    assign add_result = {1'b0, operand_a} + {1'b0, operand_b};
    assign sub_result = {1'b0, operand_a} - {1'b0, operand_b};

    // Signed overflow detection
    // Overflow occurs when:
    //   - Adding two positives gives a negative
    //   - Adding two negatives gives a positive
    //   - Subtracting a negative from a positive gives a negative
    //   - Subtracting a positive from a negative gives a positive
    always_comb begin
        case (alu_op)
            ALU_ADD: signed_overflow = (operand_a[31] == operand_b[31]) && 
                                       (add_result[31] != operand_a[31]);
            ALU_SUB: signed_overflow = (operand_a[31] != operand_b[31]) && 
                                       (sub_result[31] != operand_a[31]);
            default: signed_overflow = 1'b0;
        endcase
    end

    // Main ALU operation
    always_comb begin
        result = 32'b0;
        
        case (alu_op)
            ALU_ADD:  result = add_result[31:0];
            ALU_SUB:  result = sub_result[31:0];
            ALU_AND:  result = operand_a & operand_b;
            ALU_OR:   result = operand_a | operand_b;
            ALU_XOR:  result = operand_a ^ operand_b;
            ALU_SLL:  result = operand_a << operand_b[4:0];
            ALU_SRL:  result = operand_a >> operand_b[4:0];
            ALU_SRA:  result = $signed(operand_a) >>> operand_b[4:0];
            ALU_SLT:  result = {31'b0, ($signed(operand_a) < $signed(operand_b))};
            ALU_SLTU: result = {31'b0, (operand_a < operand_b)};
            default:  result = 32'b0;
        endcase
    end

    // Flag generation
    assign zero_flag     = (result == 32'b0);
    assign negative_flag = result[31];
    assign carry_flag    = (alu_op == ALU_ADD) ? add_result[32] :
                           (alu_op == ALU_SUB) ? sub_result[32] : 1'b0;
    assign overflow_flag = signed_overflow;

endmodule