/*
 * SSDT for TPM 2.0 CRB device node.
 *
 * Exposes \_SB.TPM with HID "MSFT0101" so that Windows loads its
 * CRB TPM driver.  The _CRS covers the full 5-locality MMIO window
 * at 0xFED40000, length 0x5000.
 *
 * Copyright (c) 2024, Oxide Computer Company
 * SPDX-License-Identifier: BSD-2-Clause-Patent
 */

DefinitionBlock ("TpmSsdt.aml", "SSDT", 2, "OVMF  ", "OVTPMDEV", 0x00000001) {
    Scope (\_SB) {
        Device (TPM) {
            Name (_HID, "MSFT0101")
            Name (_CRS, ResourceTemplate() {
                Memory32Fixed (ReadWrite, 0xFED40000, 0x00005000)
            })
            Method (_STA, 0, NotSerialized) {
                Return (0x0F)
            }

            //
            // TCG Physical Presence Interface _DSM
            // UUID: {3DDDFAA6-361B-4EB4-A424-8D10089D1653}
            //
            // This stub satisfies Windows's requirement to evaluate _DSM
            // methods on the TPM ACPI device node.  Function return types
            // follow TCG Physical Presence Interface Specification v1.30.
            // No actual pre-OS PPI execution is performed (the VM has no
            // firmware-level PPI handler).
            //
            Method (_DSM, 4, Serialized) {
                If (LEqual (Arg0, ToUUID ("3DDDFAA6-361B-4EB4-A424-8D10089D1653"))) {
                    Switch (ToInteger (Arg2)) {
                        // 0: Query — bitmap of supported functions 0-8
                        Case (0) { Return (Buffer (2) { 0xFF, 0x01 }) }
                        // 1: Submit preferred user language (optional, stub)
                        Case (1) { Return (Zero) }
                        // 2: Submit TPM operation request v1 — Integer: 0=accepted
                        Case (2) { Return (Zero) }
                        // 3: Get pending TPM operation — Package(2){op, param}; 0=none
                        Case (3) { Return (Package (2) { 0, 0 }) }
                        // 4: Get platform pre-OS action — Integer: 2=reboot
                        Case (4) { Return (2) }
                        // 5: Return last OS-initiated op response — Package(3){req,rc,param}
                        Case (5) { Return (Package (3) { 0, 0, 0 }) }
                        // 6: Submit preferred user language v2 (stub)
                        Case (6) { Return (Zero) }
                        // 7: Return preferred user language v2
                        Case (7) { Return (Buffer (1) { 0 }) }
                        // 8: Submit TPM operation request v2 — Package(2){rc, action}
                        Case (8) { Return (Package (2) { 0, 2 }) }
                    }
                }
                Return (Buffer (1) { 0 })
            }
        }
    }
}
