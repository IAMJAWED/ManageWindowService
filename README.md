# ManageWindowService
**Manage window services task provide set of action based task to manage window service like start, stop, restart, configuration, create and delete.**

**_Uses:_**

Using Manage window service task, you can manage window-based service to perform certain task like:
* To start existing window service 
* To Stop existing window service
* To restart existing window service
* To create window service from scratch.
* To configure/re-configure existing window service.
* In addition, to delete any existing window service.

**_Installation:_**

After successful integration/installation of extension, you should be able see task under “Add task” list as follow:
![AddTask](/images/AddTask.PNG)

This “Manage window service” task will provide you below actions to be performed on window service(s).
![Actions](/images/Actions.png)

**_1.	Create Service:_**

![Create](/images/rsz_2create_list.png)
 
Use this task to create service from ground up.

Options | Description
------- | -------------
1.1 Action | Create
1.2 Service Name: | Name of the service to be created.
1.3	Service bin path: | Path to executable
1.4	Log on Account: | Log on Account for specified service
1.5	Log on Account Password: | Log on Account’s password for specified service
**_Note:_** please use Release variable to store password in locked and use variable here.
1.6	Start Mode: | Mode of Service (automatic, manual, disabled)
1.7	Service Display Name: | Display Name For specified Service
1.8	Service Description: | Description For specified Service

**_2.	Delete Service:_**

Use this task to Delete existing service(s).

![Delete_Name](/images/Delete_Name.PNG)

Options | Description
------- | -------------
2.1 Action | Delete
2.2 Service(s) Name: | Name of the service(s) to be delete.
**_Note:_** you can provide multiple services name(each service name should be new line)


**_3. Configure Service:_**

Use this task to Configure any existing service.

![Config](/images/Config.PNG)

**_4.	Start Service:_**

Use this task to Strat existing service(s).

![Start](/images/Start.PNG)

**_5.	Stop service:_**

Use this task to Stop existing service(s).

![Stop](/images/Stop.PNG)

**_6.	Restart Service:_**

Use this task to Restart any exsiting service(s).

![Restart](/images/Restart.PNG)

