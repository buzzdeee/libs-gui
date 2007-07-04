/** <title>NSObjectController</title>

   <abstract>Controller class</abstract>

   Copyright <copy>(C) 2006 Free Software Foundation, Inc.</copy>

   Author: Fred Kiefer <fredkiefer@gmx.de>
   Date: June 2006

   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
*/

#include <Foundation/NSArray.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSPredicate.h>
#include <Foundation/NSString.h>
#include <AppKit/NSObjectController.h>

@implementation NSObjectController

- (id) initWithContent: (id)content
{
  if ((self = [super init]) != nil)
    {
      [self setContent: content];
      [self setObjectClass: [NSMutableDictionary class]];
      [self setEditable: YES];
    }

  return self;
}

- (id) init
{
  return [self initWithContent: nil];
}

- (void) dealloc
{
  RELEASE(_content);
  RELEASE(_entity_name_key);
  RELEASE(_fetch_predicate);
  [super dealloc];
}

- (void) encodeWithCoder: (NSCoder *)aCoder
{ 
  [super encodeWithCoder: aCoder];
  // TODO
}

- (id) initWithCoder: (NSCoder *)aDecoder
{ 
  self = [super initWithCoder: aDecoder];
  // TODO

  if ([self automaticallyPreparesContent])
  {
    if ([self managedObjectContext] != nil)
      {
	[self fetch: aDecoder];  
      }
    else 
      {
	[self prepareContent];
      }
  }

  return self; 
}

- (id) content
{
  return _content;
}

- (void) setContent: (id)content
{
  ASSIGN(_content, content);
}

- (Class) objectClass
{
  return _object_class;
}

- (void) setObjectClass: (Class)aClass
{
  _object_class = aClass;
}

- (id) newObject
{
  return [[[self objectClass] alloc] init];
}

- (void) prepareContent
{
  id new = [self newObject];

  [self setContent: new];
  RELEASE(new);
}

- (BOOL) automaticallyPreparesContent
{
  return _automatically_prepares_content;
}

- (void) setAutomaticallyPreparesContent: (BOOL)flag
{ 
  _automatically_prepares_content = flag;
}

- (void) add: (id)sender
{
  id new = [self newObject];

  [self addObject: new];
  RELEASE(new);
}

- (void) addObject: (id)obj
{
  [self setContent: obj];
  // TODO
}

- (void) remove: (id)sender
{
  [self removeObject: [self content]];
}

- (void) removeObject: (id)obj
{
  if (obj == [self content])
    {
      [self setContent: nil];
      // TODO
    }
}

- (BOOL) canAdd
{
  return YES;
}

- (BOOL) canRemove
{
  return YES;
}

- (BOOL) isEditable
{
  return _is_editable;
}

- (void) setEditable: (BOOL)flag
{
  _is_editable = flag;
}

- (NSArray*) selectedObjects
{
  // TODO
  return nil;
}

- (id) selection
{
  // TODO
  return nil;
}


- (BOOL) validateMenuItem: (id <NSMenuItem>)item
{
  SEL  action = [item action];

  if (sel_eq(action, @selector(add:)))
    {
      return [self canAdd];
    }
  else if (sel_eq(action, @selector(remove:)))
    {
      return [self canRemove];
    }

  return YES;
}

- (NSString*) entityNameKey
{
  return _entity_name_key;
}

- (void) setEntityName: (NSString*)entityName
{
  ASSIGN(_entity_name_key, entityName);
}

- (NSPredicate*) fetchPredicate
{
  return _fetch_predicate;
}

- (void) setFetchPredicate: (NSPredicate*)predicate
{
  ASSIGN(_fetch_predicate, predicate);
}

- (void) fetch: (id)sender
{
  NSError *error;
  
  [self fetchWithRequest: nil merge: NO error: &error];
}

- (BOOL) fetchWithRequest: (NSFetchRequest*)fetchRequest
                    merge: (BOOL)merge
                    error: (NSError**)error
{
  // TODO
  //[_managed_object_context executeFetchRequest: fetchRequest error: error];
  return NO;
}

- (NSManagedObjectContext*) managedObjectContext
{
  return _managed_object_context;
}

- (void) setManagedObjectContext: (NSManagedObjectContext*)managedObjectContext
{
  _managed_object_context = managedObjectContext;
}

@end