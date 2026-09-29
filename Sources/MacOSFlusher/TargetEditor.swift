import AppKit
import SwiftUI

struct TargetEditor: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    private let original: UserTarget
    @State private var name: String
    @State private var folders: String
    @State private var command: String
    @State private var understood = false

    init(target: UserTarget) {
        original = target
        _name = State(initialValue: target.name)
        _folders = State(initialValue: target.paths.joined(separator: "\n"))
        _command = State(initialValue: target.command ?? "")
    }

    private var paths: [String] {
        folders.split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    private var cleanup: String? {
        let text = command.trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? nil : text
    }

    private var title: String {
        name.trimmingCharacters(in: .whitespaces)
    }

    private var problem: String? {
        if title.isEmpty { return Messages.nameMissing }
        if paths.isEmpty && cleanup == nil { return Messages.nothingToClean }
        for path in paths {
            if let refused = store.refusal(of: path) { return path + ": " + refused }
        }
        return nil
    }

    private var confirmed: Bool {
        original.accepted != nil && paths == original.paths && cleanup == original.command
    }

    private var exists: Bool {
        store.userTargets.contains { $0.id == original.id }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            field(Messages.editorName) {
                TextField("", text: $name)
            }
            field(Messages.editorFolders, hint: Messages.editorFoldersHint) {
                TextEditor(text: $folders)
                    .font(.system(.body, design: .monospaced))
                    .frame(height: 72)
                    .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.secondary.opacity(0.3)))
                Button(Messages.chooseFolder) { choose() }
            }
            field(Messages.editorCommand, hint: Messages.editorCommandHint) {
                TextField("", text: $command)
                    .font(.system(.body, design: .monospaced))
            }
            Divider()
            Text(Messages.responsibility)
                .fixedSize(horizontal: false, vertical: true)
            if !confirmed {
                Toggle(Messages.understood, isOn: $understood)
                    .toggleStyle(.checkbox)
            }
            if let problem {
                Text(problem)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack {
                if exists {
                    Button("Delete", role: .destructive) {
                        store.remove(original)
                        dismiss()
                    }
                }
                Spacer()
                Button("Cancel", role: .cancel) { dismiss() }
                Button("Save") {
                    store.save(UserTarget(
                        id: original.id,
                        name: title,
                        paths: paths,
                        command: cleanup,
                        accepted: confirmed ? original.accepted : Date()
                    ))
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(problem != nil || !(confirmed || understood))
            }
        }
        .padding(20)
        .frame(width: 520)
    }

    private func field<Content: View>(_ label: String, hint: String? = nil, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label).font(.callout.weight(.medium))
            content()
            if let hint {
                Text(hint)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func choose() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = true
        guard panel.runModal() == .OK else { return }
        let chosen = panel.urls.map { ($0.path as NSString).abbreviatingWithTildeInPath }
        folders = (paths + chosen).joined(separator: "\n")
    }
}
