import Foundation

/// Door payload. Keeps digit runs of length 8 to 14. A 12-digit UPC-A gains a leading 0.
enum DoorCode {
    static func accept(_ raw: String) -> String? {
        var run = ""
        var chosen: String?
        func close() {
            if (8...14).contains(run.count) {
                chosen = run
            }
            run = ""
        }
        for character in raw {
            if character.isNumber {
                run.append(character)
            } else {
                close()
            }
        }
        close()
        guard var code = chosen else { return nil }
        if code.count == 12 {
            code = "0" + code
        }
        return code
    }
}
