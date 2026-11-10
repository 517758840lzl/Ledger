//
//  ReminderSettingsViews.swift
//  Ledger
//
//  Created by Ketty on 2026/10/18.
//

import SwiftUI
import UserNotifications

struct ReminderSettingsView: View {
    @EnvironmentObject private var store: LedgerStore
    @State private var notificationsAllowed = true
    @State private var showTimePicker = false

    private var timeBinding: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(
                    from: DateComponents(hour: store.settings.reminderHour, minute: store.settings.reminderMinute)
                ) ?? Date()
            },
            set: { date in
                let c = Calendar.current.dateComponents([.hour, .minute], from: date)
                store.settings.reminderHour = c.hour ?? 21
                store.settings.reminderMinute = c.minute ?? 30
                store.save()
                ReminderScheduler.resync(store.settings)
            }
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Toggle(L10n.t("settings.reminder_daily"), isOn: Binding(
                    get: { store.settings.reminderEnabled },
                    set: { v in
                        store.settings.reminderEnabled = v
                        store.save()
                        if v {
                            ReminderScheduler.requestAndSchedule(store.settings) { allowed in
                                notificationsAllowed = allowed
                            }
                        } else {
                            ReminderScheduler.cancel()
                        }
                    }
                ))
                .padding()
                .background(RoundedRectangle(cornerRadius: 16).fill(AppTheme.card))

                Text(L10n.t("settings.reminder_time"))
                    .font(.footnote)
                    .foregroundStyle(AppTheme.textSecondary)
                Button { showTimePicker = true } label: {
                    Text(String(format: "%02d:%02d", store.settings.reminderHour, store.settings.reminderMinute))
                        .font(.title3.weight(.bold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Capsule().fill(AppTheme.card))
                }

                Text(L10n.t("settings.reminder_footer"))
                    .font(.footnote)
                    .foregroundStyle(AppTheme.textSecondary)

                if !notificationsAllowed {
                    Text(L10n.t("settings.reminder_permission_off"))
                        .font(.subheadline)
                        .foregroundStyle(Color(red: 0.75, green: 0.15, blue: 0.2))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color(red: 1, green: 0.92, blue: 0.93)))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.t("settings.reminder_preview_title"))
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                    HStack(spacing: 12) {
                        LedgerMark(symbol: "MarkBell", point: 17, weight: .regular)
                            .foregroundStyle(AppTheme.greenDark)
                            .frame(width: 36, height: 36)
                            .background(RoundedRectangle(cornerRadius: 10).fill(AppTheme.greenSoft))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Qingji").font(.subheadline.weight(.semibold))
                            Text(L10n.t("settings.reminder_preview_body"))
                                .font(.caption)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 16).fill(AppTheme.card))
                }
            }
            .padding(16)
        }
        .background(AppTheme.page.ignoresSafeArea())
        .navigationTitle(L10n.reminder)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showTimePicker) {
            NavigationStack {
                DatePicker("", selection: timeBinding, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .navigationTitle(L10n.t("settings.reminder_time"))
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button(L10n.done) { showTimePicker = false }
                        }
                    }
            }
            .presentationDetents([.medium])
        }
        .onAppear {
            ReminderScheduler.checkPermission { notificationsAllowed = $0 }
        }
    }
}

enum ReminderScheduler {
    static let id = "ledger.daily.reminder"

    static func checkPermission(_ done: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                done(settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional)
            }
        }
    }

    static func requestAndSchedule(_ settings: AppSettings, done: ((Bool) -> Void)? = nil) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { ok, _ in
            DispatchQueue.main.async {
                if ok { schedule(settings) }
                done?(ok)
            }
        }
    }

    static func resync(_ settings: AppSettings) {
        guard settings.reminderEnabled else { cancel(); return }
        schedule(settings)
    }

    static func schedule(_ settings: AppSettings) {
        cancel()
        var date = DateComponents()
        date.hour = settings.reminderHour
        date.minute = settings.reminderMinute
        let content = UNMutableNotificationContent()
        content.title = "Qingji"
        content.body = L10nPack.text("settings.reminder_preview_body", language: settings.languageCode)
        content.sound = .default
        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
        let req = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req)
    }

    static func cancel() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }
}
