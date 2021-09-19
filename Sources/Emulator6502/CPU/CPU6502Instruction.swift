enum CPU6502Instruction: Int {
case I_NEXT_OP, I_PC_INCR, I_SP_INCR, I_SP_DECR, I_WRITE,
  I_INTL_to_ADDR_B, I_INTH_to_ADDR_B, I_BRK_SEI,
  I_PC_to_ADDR_B, I_ADDR_B_to_PC, I_SP_to_ADDR_B,
  I_AD_to_ADDR_B, I_DATA_to_ADH, I_DATA_to_ADL,
  I_PCH_to_DATA, I_PCL_to_DATA, I_P_to_DATA,
  I_DATA_to_PCH, I_DATA_to_PCL, I_DATA_to_P,
  I_CLC, I_CLD, I_CLI, I_CLV, I_SEC, I_SED, I_SEI,
  I_A_to_DATA, I_DATA_to_A, I_ADL_INCR, I_ADH_INCR,
  I_ADC, I_ADL_plus_X, I_ADL_plus_Y, I_CHK_carry,
  I_SBC, I_AND, I_EOR, I_ORA, I_CMP, I_CPX, I_CPY,
  I_DATA_to_X, I_DATA_to_Y,
  I_ASL, I_LSR, I_ROL, I_ROR,
  I_X_to_DATA, I_Y_to_DATA,
  I_PCL_plus_DATA, I_PCH_INCR,
  I_BCC
}
