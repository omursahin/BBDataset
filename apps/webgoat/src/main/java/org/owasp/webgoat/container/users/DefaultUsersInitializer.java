package org.owasp.webgoat.container.users;

import lombok.AllArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;

/**
 * ============================================================================
 * CUSTOM ADDITION: Automatically creates default users when WebGoat starts
 * ============================================================================
 * This component creates two test users if no users exist in the database:
 * - testuser / testuser
 * - testuser2 / testuser
 *
 * ============================================================================
 */
@Slf4j
@Component
@AllArgsConstructor
public class DefaultUsersInitializer implements ApplicationRunner {

    private final UserService userService;
    private final UserRepository userRepository;

    @Override
    public void run(ApplicationArguments args) {
        // Only create default users if database is empty
        if (userRepository.count() == 0) {
            log.info("============================================================================");
            log.info("No users found. Creating default test users...");
            log.info("============================================================================");

            try {
                // Create first test user
                userService.addUser("testuser", "testuser");
                log.info("✓ Created default user: testuser / testuser");

                // Create second test user
                userService.addUser("testuser2", "testuser");
                log.info("✓ Created default user: testuser2 / testuser");

                log.info("============================================================================");
                log.info("Default users created successfully");
                log.info("============================================================================");
            } catch (Exception e) {
                log.error("============================================================================");
                log.error("Error creating default users", e);
                log.error("============================================================================");
            }
        } else {
            log.debug("Users already exist in database. Skipping default user creation.");
        }
    }
}
