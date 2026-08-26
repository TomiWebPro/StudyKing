# Mentor Agent: Add Syllabus/Topic Structure Exploration Tool

**Severity:** minor
**Affected area:** Mentor Mode — Agent Toolset
**Reported by:** codebase audit

## Description

The mentor agent cannot query the structure of subjects, topics, or syllabi. When a student asks "What topics are in my physics syllabus?" or "What are the prerequisites for calculus?", the agent has no tool to look up this information. It must rely on whatever context was built at chat initialization.

The existing `MentorContextBuilder` includes the current plan's roadmap milestones and weak topics, but it doesn't include the full topic tree, prerequisite relationships, or syllabus structure. If the student asks about topics they haven't studied yet, or wants to understand the learning path, the agent is blind.

## Expected behavior

The mentor agent should be able to:
- List all subjects with topic counts and progress
- Show the topic tree for a subject (hierarchy and dependencies)
- Query prerequisites and downstream topics for any topic
- Show topic progress and mastery status
- Suggest a learning order based on prerequisites

## Actual behavior

No syllabus/topic structure tool exists. The agent can only reference the static context provided at chat start.

## Code analysis

- `lib/core/data/repositories/topic_repository.dart` — Topic CRUD, list by subject
- `lib/features/subjects/data/repositories/subject_repository.dart` — Subject CRUD, topic management
- `lib/features/subjects/data/models/topic_dependency_model.dart` — `TopicDependency` with prerequisite/downstream tracking, priority calculation
- `lib/features/subjects/services/subject_service.dart` — Subject management with topic relationships
- `lib/features/planner/services/syllabus_resolver.dart` — Topological sort of syllabus for learning order

## Suggested approach

1. **Create a new `GetSyllabusStructureTool`** implementing `AgentTool`:
   ```dart
   class GetSyllabusStructureTool extends AgentTool {
     name: 'get_syllabus_structure'
     description: 'Explore subject structure, topic trees, prerequisites, and progress.'
     parameters: {
       type: 'object',
       properties: {
         subjectId: {type: 'string', description: 'Subject to explore'},
         topicId: {type: 'string', description: 'Specific topic to get details for'},
         includePrerequisites: {type: 'boolean', default: true},
         includeProgress: {type: 'boolean', default: true},
       },
       required: [],
     }
   }
   ```

2. **Return structured syllabus data**:
   ```json
   {
     "subjectId": "subj_physics",
     "subjectName": "IB Physics HL",
     "topicCount": 12,
     "completedTopics": 5,
     "overallProgress": 0.42,
     "topics": [
       {
         "id": "topic_kinematics",
         "name": "Kinematics",
         "mastery": "developing",
         "accuracy": 0.72,
         "prerequisites": [],
         "downstreamTopics": ["topic_dynamics", "topic_energy"],
         "estimatedMinutes": 180,
         "isReady": true
       },
       {
         "id": "topic_dynamics",
         "name": "Dynamics",
         "mastery": "novice",
         "accuracy": 0.0,
         "prerequisites": ["topic_kinematics"],
         "downstreamTopics": ["topic_circular_motion"],
         "estimatedMinutes": 240,
         "isReady": false,
         "blockedBy": ["topic_kinematics"]
       }
     ],
     "suggestedNextTopic": "topic_dynamics",
     "explanation": "Complete Kinematics first (72% accuracy), then start Dynamics."
   }
   ```

3. **Wire through `SubjectRepository`**, `TopicRepository`, and `TopicDependency` models
