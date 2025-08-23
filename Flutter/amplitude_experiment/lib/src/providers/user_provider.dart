import '../models/user.dart';

/// Interface for providing user information to the experiment client
abstract class ExperimentUserProvider {
  /// Get the current user
  ExperimentUser getUser();
  
  /// Update the current user
  void setUser(ExperimentUser user);
  
  /// Subscribe to user changes
  void addListener(Function(ExperimentUser) listener);
  
  /// Unsubscribe from user changes
  void removeListener(Function(ExperimentUser) listener);
}