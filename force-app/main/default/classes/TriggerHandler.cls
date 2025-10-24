/**
 * @description Base abstract class for all Trigger Handlers.
 * Provides a framework to execute the trigger logic.
 * Based on the Vantegrate Standard 
 * @author Vantegrate Development Team (adaptated by Mateo Fernandez)
 */
public virtual class TriggerHandler {

    /**
     * @description Main method that is called by the Trigger.
     * Redirects the flow to the correct method based on the context of the trigger.
     */
    public void run() {
        if (Trigger.isExecuting) {
            if (Trigger.isInsert) {
                if (Trigger.isBefore) {
                    this.beforeInsert();
                } else if (Trigger.isAfter) {
                    this.afterInsert();
                }
            } else if (Trigger.isUpdate) {
                if (Trigger.isBefore) {
                    this.beforeUpdate();
                } else if (Trigger.isAfter) {
                    this.afterUpdate();
                }
            } else if (Trigger.isDelete) {
                if (Trigger.isBefore) {
                    this.beforeDelete();
                } else if (Trigger.isAfter) {
                    this.afterDelete();
                }
            } else if (Trigger.isUndelete) {
                if (Trigger.isAfter) {
                    this.afterUndelete();
                }
            }
        }
    }

    // --- Abstract methods to be implemented by the subclasses ---

    protected virtual void beforeInsert() {}
    protected virtual void afterInsert() {}
    protected virtual void beforeUpdate() {}
    protected virtual void afterUpdate() {}
    protected virtual void beforeDelete() {}
    protected virtual void afterDelete() {}
    protected virtual void afterUndelete() {}
}