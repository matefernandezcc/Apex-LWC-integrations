/**
 * @description Handler class for TankTrigger.
 * Implements logic for after insert events.
 * @author Mateo Fernandez
 */
public class TankTriggerHandler extends TriggerHandler {

    /**
     * @description After insert logic.
     * If a single tank is created, it enqueues a job to get a Bitly link.
     */
    public override void afterInsert() {
        // Trigger size is ONLY 1 because we are using a single tank
        if (Trigger.new.size() == 1) {
            
            Id singleTankId = Trigger.new[0].Id;

            // We use Queueable (asynchronous) because we cannot
            // make 'callouts' (HTTP calls) from a trigger.
            System.enqueueJob(new BitlyServiceQueueable(singleTankId));
        }
    }
}